"""Claude agent service — orchestrates tool calls against Salesforce data."""

import json
import os
import time
from datetime import date, datetime

import anthropic
from dotenv import load_dotenv

from tools.query_group_bookings import (
    TOOL_QUERY_AT_RISK,
    TOOL_PIPELINE_BY_STAGE,
    query_group_bookings_at_risk,
    query_pipeline_by_stage,
)
from tools.query_property_pipeline import (
    TOOL_PIPELINE_BY_PROPERTY,
    query_pipeline_by_property,
)
from tools.query_corporate_accounts import (
    TOOL_ACCOUNTS_NEEDING_ATTENTION,
    query_accounts_needing_attention,
)
from tools.query_revenue_forecast import (
    TOOL_CLOSING_THIS_QUARTER,
    query_closing_this_quarter,
)
from tools.query_team_activity import (
    TOOL_RECENT_ACTIVITIES,
    query_recent_activities,
)

load_dotenv()

# ── Constants ─────────────────────────────────────────────────────────────────

MODEL = "claude-sonnet-4-20250514"

SYSTEM_PROMPT = """You are an AI assistant for Marriott International revenue managers. \
You help them understand their group booking pipeline, corporate accounts, \
revenue forecasts, and sales team activity using live Salesforce data.

You have access to these tools:
- query_group_bookings_at_risk
- query_pipeline_by_stage
- query_pipeline_by_property
- query_accounts_needing_attention
- query_closing_this_quarter
- query_recent_activities

Always:
- Be concise and business-focused
- Highlight risks and opportunities
- Suggest next actions
- Reference specific properties and accounts by name
- Format numbers as currency ($1.2M) or percentages
- Never use ## or # markdown headers in your responses. Never use raw markdown.
- Use plain text only. For lists use plain dashes. Keep responses concise and insight-focused."""

TOOLS = [
    TOOL_QUERY_AT_RISK,
    TOOL_PIPELINE_BY_STAGE,
    TOOL_PIPELINE_BY_PROPERTY,
    TOOL_ACCOUNTS_NEEDING_ATTENTION,
    TOOL_CLOSING_THIS_QUARTER,
    TOOL_RECENT_ACTIVITIES,
]

TOOL_MAP: dict[str, callable] = {
    "query_group_bookings_at_risk":     query_group_bookings_at_risk,
    "query_pipeline_by_stage":          query_pipeline_by_stage,
    "query_pipeline_by_property":       query_pipeline_by_property,
    "query_accounts_needing_attention": query_accounts_needing_attention,
    "query_closing_this_quarter":       query_closing_this_quarter,
    "query_recent_activities":          query_recent_activities,
}

# Suggested chart type per tool
_CHART_HINTS: dict[str, str] = {
    "query_pipeline_by_stage":          "pie",
    "query_pipeline_by_property":       "bar",
    "query_closing_this_quarter":       "bar",
    "query_group_bookings_at_risk":     "table",
    "query_accounts_needing_attention": "table",
    "query_recent_activities":          "table",
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _serialise(obj):
    """JSON-serialise any non-standard types that may come back from Salesforce."""
    if isinstance(obj, (date, datetime)):
        return obj.isoformat()
    raise TypeError(f"Object of type {type(obj)} is not JSON serialisable")


def _rows_to_json(rows: list[dict]) -> str:
    return json.dumps(rows, default=_serialise)


def _extract_columns(rows: list[dict]) -> list[str]:
    return list(rows[0].keys()) if rows else []


def _build_chart_data(tool_name: str, rows: list[dict]) -> dict:
    """Build a chart-ready payload from Salesforce result rows."""
    chart_type = _CHART_HINTS.get(tool_name, "table")

    if not rows or chart_type == "table":
        return {"type": "table", "labels": [], "datasets": []}

    if tool_name == "query_pipeline_by_stage":
        # Aggregate SOQL returns lowercase aliased keys: stagename, total_deals, total_value
        stage_key = next((k for k in rows[0] if "stage" in k.lower()), "stagename")
        value_key = next((k for k in rows[0] if "value" in k.lower()), "total_value")
        return {
            "type": "pie",
            "labels": [r.get(stage_key, "") for r in rows],
            "datasets": [{
                "label": "Pipeline Value",
                "data":  [float(r.get(value_key) or 0) for r in rows],
            }],
        }

    if tool_name == "query_pipeline_by_property":
        account_key = next((k for k in rows[0] if "account" in k.lower() and "name" in k.lower()), "account_name")
        value_key   = next((k for k in rows[0] if "value" in k.lower()), "total_value")
        # Group by account, sum values across stages
        totals: dict[str, float] = {}
        for r in rows:
            label = r.get(account_key, "Unknown")
            totals[label] = totals.get(label, 0) + float(r.get(value_key) or 0)
        labels = list(totals.keys())
        return {
            "type": "bar",
            "labels": labels,
            "datasets": [{"label": "Pipeline Value ($)", "data": list(totals.values())}],
        }

    if tool_name == "query_closing_this_quarter":
        name_key  = "name"
        value_key = "amount"
        return {
            "type": "bar",
            "labels": [r.get(name_key, "") for r in rows],
            "datasets": [{"label": "Amount ($)", "data": [float(r.get(value_key) or 0) for r in rows]}],
        }

    return {"type": "table", "labels": [], "datasets": []}


# ── Main agent function ───────────────────────────────────────────────────────

def ask_agent(question: str) -> dict:
    """
    Run the Claude agent loop for a single user question against Salesforce.

    Returns:
        summary        – Claude's plain-English answer
        data           – raw rows from the last tool call
        columns        – column names from that result set
        chart_type     – suggested visualisation type
        chart_data     – chart-ready payload
        query_time_ms  – total wall-clock time
    """
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    messages = [{"role": "user", "content": question}]

    last_tool_name: str = ""
    last_rows: list[dict] = []
    t0 = time.monotonic()

    while True:
        response = client.messages.create(
            model=MODEL,
            max_tokens=2048,
            system=SYSTEM_PROMPT,
            tools=TOOLS,
            messages=messages,
        )

        messages.append({"role": "assistant", "content": response.content})

        if response.stop_reason == "end_turn":
            summary = next(
                (b.text for b in response.content if hasattr(b, "text")),
                "No response generated.",
            )
            break

        if response.stop_reason == "tool_use":
            tool_results = []

            for block in response.content:
                if block.type != "tool_use":
                    continue

                tool_name  = block.name
                tool_input = block.input
                last_tool_name = tool_name

                fn = TOOL_MAP.get(tool_name)
                if fn is None:
                    result_content = json.dumps({"error": f"Unknown tool: {tool_name}"})
                else:
                    try:
                        rows = fn(**tool_input)
                        last_rows = rows
                        result_content = _rows_to_json(rows)
                    except Exception as exc:
                        result_content = json.dumps({"error": str(exc)})

                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": result_content,
                })

            messages.append({"role": "user", "content": tool_results})
            continue

        summary = next(
            (b.text for b in response.content if hasattr(b, "text")),
            f"Stopped unexpectedly: {response.stop_reason}",
        )
        break

    query_time_ms = round((time.monotonic() - t0) * 1000)

    return {
        "summary":       summary,
        "data":          json.loads(_rows_to_json(last_rows)),
        "columns":       _extract_columns(last_rows),
        "chart_type":    _CHART_HINTS.get(last_tool_name, "table"),
        "chart_data":    _build_chart_data(last_tool_name, last_rows),
        "query_time_ms": query_time_ms,
    }
