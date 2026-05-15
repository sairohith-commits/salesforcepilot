"""Corporate account query tools — backed by Salesforce SOQL."""

from services.salesforce_service import execute_soql


# ── Tool definition ───────────────────────────────────────────────────────────

TOOL_ACCOUNTS_NEEDING_ATTENTION = {
    "name": "query_accounts_needing_attention",
    "description": (
        "Find Salesforce Customer accounts with no logged activity in the last 60 days. "
        "Useful for identifying relationships at risk of lapsing. Returns account name, "
        "industry, type, last activity date, and count of open opportunities. "
        "Results are ordered oldest-contact-first."
    ),
    "input_schema": {
        "type": "object",
        "properties": {},
        "required": [],
    },
}


# ── Query function ────────────────────────────────────────────────────────────

def query_accounts_needing_attention() -> list[dict]:
    """
    Customer accounts with no activity in 60+ days, with their open opportunity count.

    Note: SOQL does not support COUNT() inside relationship subqueries, so we select
    the open Opportunity Ids and count them in Python after the query returns.
    """
    soql = """
        SELECT Id, Name, Industry,
               LastActivityDate, Type,
               (SELECT Id FROM Opportunities
                WHERE StageName NOT IN ('Closed Won', 'Closed Lost'))
        FROM Account
        WHERE LastActivityDate < LAST_N_DAYS:60
          AND Type = 'Customer'
        ORDER BY LastActivityDate ASC
        LIMIT 10
    """
    rows = execute_soql(soql)

    # _flatten turns the subquery list into an `opportunities_count` int key.
    # Rename it to something more readable.
    for row in rows:
        count_key = next(
            (k for k in row if k.endswith("_count") and "opportunit" in k.lower()), None
        )
        if count_key:
            row["open_opportunities"] = row.pop(count_key)

    return rows
