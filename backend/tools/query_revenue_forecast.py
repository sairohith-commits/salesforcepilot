"""Revenue / forecast query tools — backed by Salesforce SOQL."""

from services.salesforce_service import execute_soql


# ── Tool definition ───────────────────────────────────────────────────────────

TOOL_CLOSING_THIS_QUARTER = {
    "name": "query_closing_this_quarter",
    "description": (
        "Find Salesforce Opportunities with a CloseDate in the current quarter that "
        "are not yet Closed Won or Closed Lost. These are the deals most urgently "
        "needing attention to hit quarterly revenue targets. Returns opportunity name, "
        "amount, stage, close date, account name, and owner. Sorted by amount descending."
    ),
    "input_schema": {
        "type": "object",
        "properties": {},
        "required": [],
    },
}


# ── Query function ────────────────────────────────────────────────────────────

def query_closing_this_quarter() -> list[dict]:
    """Open opportunities with CloseDate in the current quarter, sorted by amount desc."""
    soql = """
        SELECT Id, Name, Amount, StageName,
               CloseDate, Account.Name, Owner.Name
        FROM Opportunity
        WHERE CloseDate = THIS_QUARTER
          AND StageName NOT IN ('Closed Won', 'Closed Lost')
        ORDER BY Amount DESC
        LIMIT 20
    """
    return execute_soql(soql)
