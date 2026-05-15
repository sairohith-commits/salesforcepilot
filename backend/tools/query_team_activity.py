"""Sales team activity query tools — backed by Salesforce SOQL."""

from services.salesforce_service import execute_soql


# ── Tool definition ───────────────────────────────────────────────────────────

TOOL_RECENT_ACTIVITIES = {
    "name": "query_recent_activities",
    "description": (
        "Show Salesforce Activity records (Tasks and Events) logged in the last 7 days. "
        "Use this to review what the sales team has been doing and spot who is active. "
        "Returns activity subject, date, type, owner name, and the related record name "
        "(account or opportunity). Sorted most-recent first."
    ),
    "input_schema": {
        "type": "object",
        "properties": {},
        "required": [],
    },
}


# ── Query function ────────────────────────────────────────────────────────────

def query_recent_activities() -> list[dict]:
    """Activities logged in the last 7 days, most recent first."""
    soql = """
        SELECT Id, Subject, ActivityDate,
               Type, Owner.Name,
               What.Name
        FROM Activity
        WHERE ActivityDate = LAST_N_DAYS:7
        ORDER BY ActivityDate DESC
        LIMIT 20
    """
    return execute_soql(soql)
