"""Property / account pipeline query tools — backed by Salesforce SOQL.

Pipeline-by-stage has moved to query_group_bookings.py.
This module keeps pipeline-by-account for property-level drill-down.
"""

from services.salesforce_service import execute_soql


TOOL_PIPELINE_BY_PROPERTY = {
    "name": "query_pipeline_by_property",
    "description": (
        "Show total open pipeline value grouped by Account (property) and stage. "
        "Use this to compare pipeline health across properties or hotel accounts. "
        "Returns account name, stage, deal count, and total value."
    ),
    "input_schema": {
        "type": "object",
        "properties": {},
        "required": [],
    },
}


def query_pipeline_by_property() -> list[dict]:
    """Open pipeline grouped by account and stage."""
    soql = """
        SELECT Account.Name, StageName,
               COUNT(Id) total_deals, SUM(Amount) total_value
        FROM Opportunity
        WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
        GROUP BY Account.Name, StageName
        ORDER BY Account.Name
        LIMIT 50
    """
    return execute_soql(soql)
