"""Salesforce connection and SOQL execution via simple-salesforce."""

import os
from typing import Any

from dotenv import load_dotenv
from simple_salesforce import Salesforce, SalesforceAuthenticationFailed, SalesforceExpiredSession

from pathlib import Path as _Path
load_dotenv(_Path(__file__).parent.parent / ".env", override=True)

_sf: Salesforce | None = None


def _connect() -> Salesforce:
    """Create a new authenticated Salesforce session."""
    username        = os.environ.get("SF_USERNAME")
    password        = os.environ.get("SF_PASSWORD")
    consumer_key    = os.environ.get("SF_CONSUMER_KEY")
    consumer_secret = os.environ.get("SF_CONSUMER_SECRET")
    domain          = os.environ.get("SF_DOMAIN", "login")

    if not all([username, password, consumer_key, consumer_secret]):
        raise EnvironmentError(
            "Missing Salesforce credentials. "
            "Set SF_USERNAME, SF_PASSWORD, SF_CONSUMER_KEY, and SF_CONSUMER_SECRET in backend/.env"
        )

    # Strip inline comments from domain (e.g. "login  # use 'test' for sandbox")
    domain = domain.split("#")[0].strip()

    return Salesforce(
        username=username,
        password=password,
        consumer_key=consumer_key,
        consumer_secret=consumer_secret,
        domain=domain,
    )


def get_sf() -> Salesforce:
    """Return the cached session, reconnecting if it has expired."""
    global _sf
    if _sf is None:
        _sf = _connect()
    return _sf


def _flatten(record: dict, parent_key: str = "") -> dict:
    """
    Recursively flatten nested Salesforce relationship dicts into dot-notation keys
    that are then lowercased with dots replaced by underscores.

    e.g. {"Account": {"Name": "Acme"}} → {"account_name": "Acme"}
    """
    out: dict[str, Any] = {}
    for key, val in record.items():
        if key == "attributes":
            continue
        full_key = f"{parent_key}.{key}" if parent_key else key
        if isinstance(val, dict):
            out.update(_flatten(val, full_key))
        elif isinstance(val, list):
            out[full_key.lower().replace(".", "_") + "_count"] = len(val)
        else:
            out[full_key.lower().replace(".", "_")] = val
    return out


def execute_soql(query: str) -> list[dict]:
    """
    Run a SOQL query and return results as a list of plain dicts.
    Handles session expiry by re-authenticating once.
    """
    global _sf
    sf = get_sf()

    def _run(client: Salesforce) -> list[dict]:
        result = client.query_all(query)
        return [_flatten(rec) for rec in result.get("records", [])]

    try:
        return _run(sf)
    except SalesforceExpiredSession:
        _sf = _connect()
        return _run(_sf)
    except SalesforceAuthenticationFailed as exc:
        raise RuntimeError(
            f"Salesforce authentication failed: {exc}. "
            "Check SF_USERNAME, SF_PASSWORD, SF_CONSUMER_KEY, SF_CONSUMER_SECRET, and SF_DOMAIN in .env"
        ) from exc
    except Exception as exc:
        raise RuntimeError(f"Salesforce query error: {exc}") from exc