-- SalesforcePilot — Marriott Revenue Intelligence
-- PostgreSQL schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── 1. Properties ─────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS sales_activities  CASCADE;
DROP TABLE IF EXISTS revenue_forecast  CASCADE;
DROP TABLE IF EXISTS group_bookings    CASCADE;
DROP TABLE IF EXISTS corporate_accounts CASCADE;
DROP TABLE IF EXISTS properties        CASCADE;

CREATE TABLE properties (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            TEXT        NOT NULL,
    brand           TEXT        NOT NULL,
    city            TEXT        NOT NULL,
    state           TEXT        NOT NULL,
    region          TEXT        NOT NULL,
    total_rooms     INTEGER     NOT NULL CHECK (total_rooms > 0),
    star_rating     NUMERIC(2,1) NOT NULL CHECK (star_rating BETWEEN 1 AND 5),
    general_manager TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_properties_brand  ON properties(brand);
CREATE INDEX idx_properties_region ON properties(region);

-- ── 2. Corporate Accounts ──────────────────────────────────────────────────────
CREATE TABLE corporate_accounts (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name         TEXT        NOT NULL,
    industry             TEXT        NOT NULL,
    annual_travel_spend  NUMERIC(14,2),
    preferred_brand      TEXT,
    account_manager      TEXT,
    last_contact_date    DATE,
    tier                 TEXT        NOT NULL CHECK (tier IN ('platinum','gold','silver')),
    created_at           TIMESTAMPTZ DEFAULT NOW(),
    updated_at           TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_corp_tier            ON corporate_accounts(tier);
CREATE INDEX idx_corp_last_contact    ON corporate_accounts(last_contact_date);
CREATE INDEX idx_corp_company         ON corporate_accounts(company_name);

-- ── 3. Group Bookings ──────────────────────────────────────────────────────────
CREATE TABLE group_bookings (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id        UUID        NOT NULL REFERENCES properties(id) ON DELETE RESTRICT,
    account_id         UUID        REFERENCES corporate_accounts(id) ON DELETE SET NULL,
    group_name         TEXT        NOT NULL,
    event_type         TEXT        NOT NULL CHECK (event_type IN (
                           'conference','wedding','corporate_retreat')),
    rooms_blocked      INTEGER     NOT NULL CHECK (rooms_blocked > 0),
    total_value        NUMERIC(14,2),
    stage              TEXT        NOT NULL CHECK (stage IN (
                           'Prospecting','Proposal','Negotiation','Contracted','Lost')),
    check_in_date      DATE        NOT NULL,
    check_out_date     DATE        NOT NULL CHECK (check_out_date > check_in_date),
    last_activity_date DATE,
    owner_id           TEXT,
    created_at         TIMESTAMPTZ DEFAULT NOW(),
    updated_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gb_property        ON group_bookings(property_id);
CREATE INDEX idx_gb_account         ON group_bookings(account_id);
CREATE INDEX idx_gb_stage           ON group_bookings(stage);
CREATE INDEX idx_gb_check_in        ON group_bookings(check_in_date);
CREATE INDEX idx_gb_last_activity   ON group_bookings(last_activity_date);

-- ── 4. Revenue Forecast ───────────────────────────────────────────────────────
CREATE TABLE revenue_forecast (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id          UUID        NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    month                INTEGER     NOT NULL CHECK (month BETWEEN 1 AND 12),
    year                 INTEGER     NOT NULL CHECK (year BETWEEN 2020 AND 2030),
    forecasted_revenue   NUMERIC(14,2),
    actual_revenue       NUMERIC(14,2),
    budget_revenue       NUMERIC(14,2),
    occupancy_forecast   NUMERIC(5,2) CHECK (occupancy_forecast BETWEEN 0 AND 100),
    actual_occupancy     NUMERIC(5,2) CHECK (actual_occupancy BETWEEN 0 AND 100),
    segment              TEXT        NOT NULL CHECK (segment IN ('group','transient','leisure')),
    created_at           TIMESTAMPTZ DEFAULT NOW(),
    updated_at           TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (property_id, month, year, segment)
);

CREATE INDEX idx_forecast_property    ON revenue_forecast(property_id);
CREATE INDEX idx_forecast_period      ON revenue_forecast(year, month);
CREATE INDEX idx_forecast_segment     ON revenue_forecast(segment);

-- ── 5. Sales Activities ───────────────────────────────────────────────────────
CREATE TABLE sales_activities (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id     UUID    REFERENCES corporate_accounts(id) ON DELETE SET NULL,
    booking_id     UUID    REFERENCES group_bookings(id)     ON DELETE SET NULL,
    subject        TEXT    NOT NULL,
    activity_type  TEXT    NOT NULL CHECK (activity_type IN (
                       'Site Visit','Proposal Sent','Contract Review',
                       'Follow Up Call','RFP Received')),
    activity_date  DATE    NOT NULL,
    outcome        TEXT,
    owner_id       TEXT,
    created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_account  ON sales_activities(account_id);
CREATE INDEX idx_activity_booking  ON sales_activities(booking_id);
CREATE INDEX idx_activity_date     ON sales_activities(activity_date);
CREATE INDEX idx_activity_type     ON sales_activities(activity_type);

-- ── updated_at trigger ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER trg_properties_updated
    BEFORE UPDATE ON properties
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_corp_updated
    BEFORE UPDATE ON corporate_accounts
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_gb_updated
    BEFORE UPDATE ON group_bookings
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_forecast_updated
    BEFORE UPDATE ON revenue_forecast
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
