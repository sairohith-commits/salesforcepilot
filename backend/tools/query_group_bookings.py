"""Group booking and pipeline stage query tools — backed by Salesforce SOQL."""

from services.salesforce_service import execute_soql


# ── Tool definitions ──────────────────────────────────────────────────────────

TOOL_QUERY_AT_RISK = {
    "name": "query_group_bookings_at_risk",
    "description": (
        "Find open Salesforce Opportunities (group bookings) that have had no activity "
        "in the last 30 days and are worth more than $50,000. Excludes Closed Won and "
        "Closed Lost. Returns opportunity name, account, stage, amount, close date, "
        "last activity date, and owner. Use this to identify stale pipeline at risk of "
        "going cold."
    ),
    "input_schema": {
        "type": "object",
        "properties": {},
        "required": [],
    },
}

TOOL_PIPELINE_BY_STAGE = {
    "name": "query_pipeline_by_stage",
    "description": (
        "Show the open Salesforce pipeline broken down by stage with total deal count "
        "and total value. Excludes Closed Won and Closed Lost. Use this for a funnel "
        "view of the current pipeline. Returns stage name, number of deals, and "
        "total pipeline value."
    ),
    "input_schema": {
        "type": "object",
        "properties": {},
        "required": [],
    },
}


# ── Query functions ───────────────────────────────────────────────────────────

def query_group_bookings_at_risk() -> list[dict]:
    """Open opportunities closing within 90 days, value > $50K, sorted by close date."""
    soql = """
        SELECT Id, Name, Amount, StageName,
               CloseDate, LastActivityDate, Account.Name,
               Owner.Name
        FROM Opportunity
        WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
          AND Amount > 50000
          AND CloseDate <= NEXT_N_DAYS:90
        ORDER BY CloseDate ASC
        LIMIT 20
    """
    return execute_soql(soql)


def query_pipeline_by_stage() -> list[dict]:
    """Open pipeline grouped by stage with deal count and total value."""
    soql = """
        SELECT StageName, COUNT(Id) total_deals, SUM(Amount) total_value
        FROM Opportunity
        WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
        GROUP BY StageName
    """
    return execute_soql(soql)
