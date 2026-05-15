-- SalesforcePilot — Marriott Revenue Intelligence
-- Realistic seed data — run after schema.sql

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. PROPERTIES  (8 rows)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO properties (id, name, brand, city, state, region, total_rooms, star_rating, general_manager) VALUES
  ('b1000000-0000-0000-0000-000000000001', 'Chicago Marriott Downtown',    'Marriott',     'Chicago',       'IL', 'Midwest',   1200, 4.0, 'Patricia Holt'),
  ('b1000000-0000-0000-0000-000000000002', 'NYC Times Square Marriott',    'Marriott',     'New York',      'NY', 'Northeast', 1780, 4.0, 'Daniel Ruiz'),
  ('b1000000-0000-0000-0000-000000000003', 'Ritz-Carlton San Francisco',   'Ritz-Carlton', 'San Francisco', 'CA', 'West',       336, 5.0, 'Isabelle Martin'),
  ('b1000000-0000-0000-0000-000000000004', 'W Hotel Miami',                'W Hotels',     'Miami',         'FL', 'Southeast',  408, 4.5, 'Carlos Mendes'),
  ('b1000000-0000-0000-0000-000000000005', 'Sheraton Dallas',              'Sheraton',     'Dallas',        'TX', 'South',     1840, 3.5, 'Amanda Price'),
  ('b1000000-0000-0000-0000-000000000006', 'JW Marriott Los Angeles',      'JW Marriott',  'Los Angeles',   'CA', 'West',       375, 5.0, 'Kevin Tran'),
  ('b1000000-0000-0000-0000-000000000007', 'Courtyard Boston',             'Courtyard',    'Boston',        'MA', 'Northeast',  315, 3.0, 'Rachel Simmons'),
  ('b1000000-0000-0000-0000-000000000008', 'Renaissance Las Vegas',        'Renaissance',  'Las Vegas',     'NV', 'West',      1504, 4.0, 'Steven Marsh');

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CORPORATE ACCOUNTS  (10 rows)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO corporate_accounts (id, company_name, industry, annual_travel_spend, preferred_brand, account_manager, last_contact_date, tier) VALUES
  ('c1000000-0000-0000-0000-000000000001', 'Accenture',          'Consulting',  8500000.00, 'Marriott',     'Sarah Chen',    '2026-04-28', 'platinum'),
  ('c1000000-0000-0000-0000-000000000002', 'Deloitte',           'Consulting',  7200000.00, 'Marriott',     'Sarah Chen',    '2026-05-05', 'platinum'),
  ('c1000000-0000-0000-0000-000000000003', 'American Airlines',  'Aviation',    3400000.00, 'Sheraton',     'Marcus Webb',   '2026-03-14', 'gold'),
  ('c1000000-0000-0000-0000-000000000004', 'Goldman Sachs',      'Finance',     9100000.00, 'JW Marriott',  'James Park',    '2026-05-09', 'platinum'),
  ('c1000000-0000-0000-0000-000000000005', 'Microsoft',          'Technology',  5600000.00, 'W Hotels',     'Priya Nair',    '2026-04-02', 'gold'),
  ('c1000000-0000-0000-0000-000000000006', 'McKinsey & Company', 'Consulting',  6800000.00, 'Ritz-Carlton', 'James Park',    '2026-01-20', 'platinum'),
  ('c1000000-0000-0000-0000-000000000007', 'Boeing',             'Aerospace',   2900000.00, 'Marriott',     'Priya Nair',    '2026-02-28', 'gold'),
  ('c1000000-0000-0000-0000-000000000008', 'JPMorgan Chase',     'Finance',     8800000.00, 'JW Marriott',  'James Park',    '2026-05-11', 'platinum'),
  ('c1000000-0000-0000-0000-000000000009', 'Google',             'Technology',  6100000.00, 'W Hotels',     'Tom Reyes',     '2026-04-15', 'gold'),
  ('c1000000-0000-0000-0000-000000000010', 'Pfizer',             'Healthcare',  1800000.00, 'Marriott',     'Dana Mills',    '2026-03-30', 'silver');

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. GROUP BOOKINGS  (20 rows)
-- ─────────────────────────────────────────────────────────────────────────────
-- Stage mix: 4 Prospecting, 4 Proposal, 4 Negotiation, 6 Contracted, 2 Lost
-- Some last_activity_date > 30 days ago = "at risk"
INSERT INTO group_bookings (id, property_id, account_id, group_name, event_type, rooms_blocked, total_value, stage, check_in_date, check_out_date, last_activity_date, owner_id) VALUES

  -- Contracted (revenue secured)
  ('d1000000-0000-0000-0000-000000000001',
   'b1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001',
   'Accenture North America Leadership Summit',
   'corporate_retreat', 420, 945000.00, 'Contracted',
   '2026-07-14', '2026-07-18', '2026-05-08', 'sarah.chen'),

  ('d1000000-0000-0000-0000-000000000002',
   'b1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000004',
   'Goldman Sachs Global Markets Conference',
   'conference', 900, 2050000.00, 'Contracted',
   '2026-09-22', '2026-09-26', '2026-05-11', 'james.park'),

  ('d1000000-0000-0000-0000-000000000003',
   'b1000000-0000-0000-0000-000000000006', 'c1000000-0000-0000-0000-000000000008',
   'JPMorgan Chase Executive Retreat',
   'corporate_retreat', 180, 810000.00, 'Contracted',
   '2026-06-09', '2026-06-12', '2026-05-06', 'james.park'),

  ('d1000000-0000-0000-0000-000000000004',
   'b1000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000009',
   'Google Cloud Next After-Party Block',
   'conference', 650, 1430000.00, 'Contracted',
   '2026-08-11', '2026-08-15', '2026-04-30', 'tom.reyes'),

  ('d1000000-0000-0000-0000-000000000005',
   'b1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000006',
   'McKinsey Senior Partner Gathering',
   'corporate_retreat', 120, 720000.00, 'Contracted',
   '2026-10-05', '2026-10-08', '2026-05-02', 'james.park'),

  ('d1000000-0000-0000-0000-000000000006',
   'b1000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000007',
   'Boeing Aerospace Innovation Forum',
   'conference', 310, 527000.00, 'Contracted',
   '2026-06-23', '2026-06-26', '2026-04-18', 'priya.nair'),

  -- Negotiation (closing this quarter)
  ('d1000000-0000-0000-0000-000000000007',
   'b1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000002',
   'Deloitte Midwest Regional Kickoff',
   'corporate_retreat', 380, 855000.00, 'Negotiation',
   '2026-07-07', '2026-07-10', '2026-05-07', 'sarah.chen'),

  ('d1000000-0000-0000-0000-000000000008',
   'b1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000005',
   'Microsoft Azure Partner Summit Miami',
   'conference', 275, 618750.00, 'Negotiation',
   '2026-08-18', '2026-08-22', '2026-05-03', 'priya.nair'),

  ('d1000000-0000-0000-0000-000000000009',
   'b1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000008',
   'JPMorgan Q3 Risk & Compliance Forum',
   'conference', 520, 1170000.00, 'Negotiation',
   '2026-09-15', '2026-09-18', '2026-05-10', 'james.park'),

  ('d1000000-0000-0000-0000-000000000010',
   'b1000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000001',
   'Accenture Innovation Awards Gala',
   'conference', 490, 980000.00, 'Negotiation',
   '2026-11-20', '2026-11-23', '2026-04-25', 'sarah.chen'),

  -- Proposal (at various risk levels)
  ('d1000000-0000-0000-0000-000000000011',
   'b1000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000003',
   'American Airlines Pilot Training Block',
   'corporate_retreat', 140, 196000.00, 'Proposal',
   '2026-06-30', '2026-07-05', '2026-03-10', 'marcus.webb'),  -- at risk: 63 days ago

  ('d1000000-0000-0000-0000-000000000012',
   'b1000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000010',
   'Pfizer Oncology Research Symposium',
   'conference', 220, 374000.00, 'Proposal',
   '2026-07-21', '2026-07-24', '2026-04-05', 'dana.mills'),   -- at risk: 37 days ago

  ('d1000000-0000-0000-0000-000000000013',
   'b1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000004',
   'Goldman Sachs Private Wealth Retreat',
   'corporate_retreat', 90, 495000.00, 'Proposal',
   '2026-10-12', '2026-10-15', '2026-05-04', 'james.park'),

  ('d1000000-0000-0000-0000-000000000014',
   'b1000000-0000-0000-0000-000000000006', 'c1000000-0000-0000-0000-000000000009',
   'Google Hardware Launch Event',
   'conference', 260, 585000.00, 'Proposal',
   '2026-09-08', '2026-09-11', '2026-05-09', 'tom.reyes'),

  -- Prospecting
  ('d1000000-0000-0000-0000-000000000015',
   'b1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000002',
   'Deloitte Global CEO Forum NYC',
   'conference', 700, 1575000.00, 'Prospecting',
   '2027-01-13', '2027-01-17', '2026-02-15', 'sarah.chen'),   -- at risk: 86 days ago

  ('d1000000-0000-0000-0000-000000000016',
   'b1000000-0000-0000-0000-000000000004', NULL,
   'South Beach Luxury Wedding — Johnson/Patel',
   'wedding', 85, 212500.00, 'Prospecting',
   '2026-12-05', '2026-12-08', '2026-05-01', 'carlos.mendes'),

  ('d1000000-0000-0000-0000-000000000017',
   'b1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000007',
   'Boeing Supply Chain Summit Chicago',
   'conference', 330, 561000.00, 'Prospecting',
   '2026-11-10', '2026-11-13', '2026-03-20', 'priya.nair'),   -- at risk: 52 days ago

  ('d1000000-0000-0000-0000-000000000018',
   'b1000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000005',
   'Microsoft Gaming & Entertainment Summit',
   'conference', 410, 861000.00, 'Prospecting',
   '2027-02-24', '2027-02-27', '2026-05-07', 'priya.nair'),

  -- Lost
  ('d1000000-0000-0000-0000-000000000019',
   'b1000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000003',
   'American Airlines Flight Ops Conference',
   'conference', 200, 300000.00, 'Lost',
   '2026-06-16', '2026-06-19', '2026-02-28', 'marcus.webb'),

  ('d1000000-0000-0000-0000-000000000020',
   'b1000000-0000-0000-0000-000000000005', NULL,
   'Texas Tech Alumni Weekend',
   'corporate_retreat', 160, 176000.00, 'Lost',
   '2026-07-31', '2026-08-03', '2026-01-10', 'amanda.price');

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. REVENUE FORECAST  (12 months × 2 properties × 3 segments = 72 rows)
--    Properties covered: Chicago Marriott Downtown (b1), NYC Times Square (b2)
--    Segments: group / transient / leisure
--    Seasonal pattern: summer peak, winter trough
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO revenue_forecast
    (property_id, month, year, forecasted_revenue, actual_revenue, budget_revenue, occupancy_forecast, actual_occupancy, segment)
VALUES

-- ── Chicago Marriott Downtown — group ─────────────────────────────────────────
('b1000000-0000-0000-0000-000000000001', 1,2026,  680000, 625000,  700000, 58.0, 53.5, 'group'),
('b1000000-0000-0000-0000-000000000001', 2,2026,  710000, 745000,  690000, 60.5, 63.0, 'group'),
('b1000000-0000-0000-0000-000000000001', 3,2026,  820000, 855000,  800000, 68.0, 70.2, 'group'),
('b1000000-0000-0000-0000-000000000001', 4,2026,  870000, 840000,  850000, 72.0, 69.5, 'group'),
('b1000000-0000-0000-0000-000000000001', 5,2026,  950000,      0,  920000, 78.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000001', 6,2026, 1050000,      0, 1020000, 84.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000001', 7,2026, 1180000,      0, 1150000, 91.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000001', 8,2026, 1120000,      0, 1100000, 88.5,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000001', 9,2026,  980000,      0,  960000, 80.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000001',10,2026,  890000,      0,  870000, 74.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000001',11,2026,  760000,      0,  750000, 63.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000001',12,2026,  620000,      0,  640000, 52.0,  0.0, 'group'),

-- ── Chicago Marriott Downtown — transient ─────────────────────────────────────
('b1000000-0000-0000-0000-000000000001', 1,2026,  920000, 880000,  950000, 62.0, 59.0, 'transient'),
('b1000000-0000-0000-0000-000000000001', 2,2026,  960000, 995000,  940000, 65.0, 67.5, 'transient'),
('b1000000-0000-0000-0000-000000000001', 3,2026, 1100000,1145000, 1080000, 74.0, 77.0, 'transient'),
('b1000000-0000-0000-0000-000000000001', 4,2026, 1150000,1110000, 1130000, 77.0, 74.5, 'transient'),
('b1000000-0000-0000-0000-000000000001', 5,2026, 1280000,      0, 1250000, 84.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000001', 6,2026, 1420000,      0, 1390000, 92.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000001', 7,2026, 1580000,      0, 1550000, 96.5,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000001', 8,2026, 1510000,      0, 1480000, 94.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000001', 9,2026, 1340000,      0, 1310000, 86.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000001',10,2026, 1200000,      0, 1180000, 78.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000001',11,2026, 1040000,      0, 1020000, 68.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000001',12,2026,  850000,      0,  870000, 57.0,  0.0, 'transient'),

-- ── Chicago Marriott Downtown — leisure ───────────────────────────────────────
('b1000000-0000-0000-0000-000000000001', 1,2026,  310000, 285000,  320000, 42.0, 38.5, 'leisure'),
('b1000000-0000-0000-0000-000000000001', 2,2026,  330000, 355000,  315000, 44.0, 47.0, 'leisure'),
('b1000000-0000-0000-0000-000000000001', 3,2026,  400000, 425000,  390000, 52.0, 55.0, 'leisure'),
('b1000000-0000-0000-0000-000000000001', 4,2026,  450000, 420000,  440000, 58.0, 54.0, 'leisure'),
('b1000000-0000-0000-0000-000000000001', 5,2026,  530000,      0,  510000, 65.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000001', 6,2026,  680000,      0,  660000, 76.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000001', 7,2026,  820000,      0,  800000, 88.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000001', 8,2026,  790000,      0,  770000, 85.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000001', 9,2026,  610000,      0,  590000, 70.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000001',10,2026,  500000,      0,  490000, 62.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000001',11,2026,  380000,      0,  370000, 50.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000001',12,2026,  295000,      0,  310000, 40.0,  0.0, 'leisure'),

-- ── NYC Times Square Marriott — group ─────────────────────────────────────────
('b1000000-0000-0000-0000-000000000002', 1,2026, 1050000,1010000, 1080000, 61.0, 58.5, 'group'),
('b1000000-0000-0000-0000-000000000002', 2,2026, 1120000,1185000, 1090000, 65.0, 68.5, 'group'),
('b1000000-0000-0000-0000-000000000002', 3,2026, 1350000,1290000, 1320000, 74.0, 70.5, 'group'),
('b1000000-0000-0000-0000-000000000002', 4,2026, 1420000,1460000, 1390000, 78.0, 80.0, 'group'),
('b1000000-0000-0000-0000-000000000002', 5,2026, 1600000,      0, 1570000, 84.5,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000002', 6,2026, 1780000,      0, 1750000, 90.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000002', 7,2026, 1950000,      0, 1920000, 95.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000002', 8,2026, 1870000,      0, 1840000, 93.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000002', 9,2026, 1640000,      0, 1610000, 87.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000002',10,2026, 1480000,      0, 1450000, 80.5,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000002',11,2026, 1210000,      0, 1190000, 67.0,  0.0, 'group'),
('b1000000-0000-0000-0000-000000000002',12,2026,  980000,      0, 1010000, 55.0,  0.0, 'group'),

-- ── NYC Times Square Marriott — transient ─────────────────────────────────────
('b1000000-0000-0000-0000-000000000002', 1,2026, 1480000,1420000, 1520000, 68.0, 65.0, 'transient'),
('b1000000-0000-0000-0000-000000000002', 2,2026, 1560000,1630000, 1530000, 71.0, 74.5, 'transient'),
('b1000000-0000-0000-0000-000000000002', 3,2026, 1860000,1800000, 1820000, 82.0, 79.0, 'transient'),
('b1000000-0000-0000-0000-000000000002', 4,2026, 1940000,1990000, 1900000, 85.0, 87.5, 'transient'),
('b1000000-0000-0000-0000-000000000002', 5,2026, 2180000,      0, 2150000, 91.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000002', 6,2026, 2440000,      0, 2410000, 96.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000002', 7,2026, 2680000,      0, 2650000, 99.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000002', 8,2026, 2580000,      0, 2550000, 97.5,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000002', 9,2026, 2300000,      0, 2270000, 92.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000002',10,2026, 2060000,      0, 2030000, 87.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000002',11,2026, 1720000,      0, 1690000, 76.0,  0.0, 'transient'),
('b1000000-0000-0000-0000-000000000002',12,2026, 1380000,      0, 1420000, 63.0,  0.0, 'transient'),

-- ── NYC Times Square Marriott — leisure ───────────────────────────────────────
('b1000000-0000-0000-0000-000000000002', 1,2026,  690000, 650000,  710000, 55.0, 52.0, 'leisure'),
('b1000000-0000-0000-0000-000000000002', 2,2026,  730000, 780000,  710000, 58.0, 62.0, 'leisure'),
('b1000000-0000-0000-0000-000000000002', 3,2026,  890000, 860000,  870000, 66.0, 63.5, 'leisure'),
('b1000000-0000-0000-0000-000000000002', 4,2026,  960000, 1005000, 940000, 70.0, 73.5, 'leisure'),
('b1000000-0000-0000-0000-000000000002', 5,2026, 1100000,      0, 1080000, 78.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000002', 6,2026, 1310000,      0, 1290000, 87.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000002', 7,2026, 1520000,      0, 1500000, 94.5,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000002', 8,2026, 1460000,      0, 1440000, 92.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000002', 9,2026, 1150000,      0, 1130000, 82.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000002',10,2026,  960000,      0,  940000, 73.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000002',11,2026,  750000,      0,  730000, 60.0,  0.0, 'leisure'),
('b1000000-0000-0000-0000-000000000002',12,2026,  580000,      0,  600000, 48.0,  0.0, 'leisure');

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. SALES ACTIVITIES  (25 rows)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO sales_activities (account_id, booking_id, subject, activity_type, activity_date, outcome, owner_id) VALUES

  -- Recent activities (healthy pipeline)
  ('c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001',
   'Confirmed final rooming list and F&B minimums',
   'Contract Review',    '2026-05-08', 'Contract amendments signed — booking confirmed',       'sarah.chen'),

  ('c1000000-0000-0000-0000-000000000004', 'd1000000-0000-0000-0000-000000000002',
   'Goldman Sachs room block — final terms',
   'Contract Review',    '2026-05-11', 'Executed — deposit received',                          'james.park'),

  ('c1000000-0000-0000-0000-000000000008', 'd1000000-0000-0000-0000-000000000003',
   'JPMorgan retreat — site visit with event team',
   'Site Visit',         '2026-05-06', 'Client loved the boardroom suite — very likely to sign', 'james.park'),

  ('c1000000-0000-0000-0000-000000000009', 'd1000000-0000-0000-0000-000000000004',
   'Google block rates and AV requirements',
   'Follow Up Call',     '2026-04-30', 'AV specs confirmed — tech rider sent to property',     'tom.reyes'),

  ('c1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000007',
   'Deloitte Midwest — revised proposal with F&B upgrade',
   'Proposal Sent',      '2026-05-07', 'Proposal under internal review — decision by May 20',  'sarah.chen'),

  ('c1000000-0000-0000-0000-000000000005', 'd1000000-0000-0000-0000-000000000008',
   'Microsoft Azure Summit — contract redline review',
   'Contract Review',    '2026-05-03', 'Legal review in progress — 2 open items',               'priya.nair'),

  ('c1000000-0000-0000-0000-000000000008', 'd1000000-0000-0000-0000-000000000009',
   'JPMorgan Q3 forum — room block increase request',
   'Follow Up Call',     '2026-05-10', 'Block expanded from 480 to 520 rooms — repricing needed', 'james.park'),

  ('c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000010',
   'Accenture Awards — menu tasting and AV walkthrough',
   'Site Visit',         '2026-04-25', 'Strong positive feedback — proposal revision in progress', 'sarah.chen'),

  ('c1000000-0000-0000-0000-000000000004', 'd1000000-0000-0000-0000-000000000013',
   'Goldman Sachs private retreat — RFP response',
   'RFP Received',       '2026-05-04', 'RFP submitted — awaiting scoring',                     'james.park'),

  ('c1000000-0000-0000-0000-000000000009', 'd1000000-0000-0000-0000-000000000014',
   'Google Hardware Launch — proposal walk-through',
   'Proposal Sent',      '2026-05-09', 'Client requested pricing for two date options',         'tom.reyes'),

  -- Activities tied to at-risk bookings (last contact > 30 days ago)
  ('c1000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000011',
   'American Airlines pilot block — initial proposal review',
   'Proposal Sent',      '2026-03-10', 'No response — needs follow up ASAP',                   'marcus.webb'),

  ('c1000000-0000-0000-0000-000000000010', 'd1000000-0000-0000-0000-000000000012',
   'Pfizer Oncology — space walkthrough',
   'Site Visit',         '2026-04-05', 'Team liked venue but awaiting budget approval',         'dana.mills'),

  ('c1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000015',
   'Deloitte CEO Forum — discovery call',
   'Follow Up Call',     '2026-02-15', 'Early stage — RFP expected Q2',                        'sarah.chen'),

  ('c1000000-0000-0000-0000-000000000007', 'd1000000-0000-0000-0000-000000000017',
   'Boeing Supply Chain Summit — preliminary site visit',
   'Site Visit',         '2026-03-20', 'Positive — waiting on Boeing travel freeze to lift',   'priya.nair'),

  -- Activities tied to lost deals
  ('c1000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000019',
   'American Airlines Flight Ops — final negotiation',
   'Contract Review',    '2026-02-28', 'Lost to Hilton on rate — 8% gap',                      'marcus.webb'),

  -- New prospecting activities (no booking yet)
  ('c1000000-0000-0000-0000-000000000006', NULL,
   'McKinsey 2027 annual planning — intro call',
   'Follow Up Call',     '2026-05-05', 'Interested in exclusive property buy-out options',     'james.park'),

  ('c1000000-0000-0000-0000-000000000005', NULL,
   'Microsoft — inbound RFP for Q1 2027 all-hands',
   'RFP Received',       '2026-05-08', 'RFP covers 600 rooms across 3 nights — high value',   'priya.nair'),

  ('c1000000-0000-0000-0000-000000000010', NULL,
   'Pfizer — follow up on 2027 medical congress block',
   'Follow Up Call',     '2026-05-06', 'Budget confirmed — formal RFP expected by June',       'dana.mills'),

  ('c1000000-0000-0000-0000-000000000007', NULL,
   'Boeing — exploratory call for 2027 leadership retreat',
   'Follow Up Call',     '2026-04-22', 'Travel freeze lifted May 1 — re-engaging',             'priya.nair'),

  ('c1000000-0000-0000-0000-000000000001', NULL,
   'Accenture — 2027 global partner conference RFP',
   'RFP Received',       '2026-05-11', 'Major opportunity — 1,200 rooms, 5 nights',            'sarah.chen'),

  -- Overdue follow-ups
  ('c1000000-0000-0000-0000-000000000003', NULL,
   'American Airlines — re-engagement after lost deal',
   'Follow Up Call',     '2026-04-01', 'Left voicemail — no callback yet',                     'marcus.webb'),

  ('c1000000-0000-0000-0000-000000000006', 'd1000000-0000-0000-0000-000000000005',
   'McKinsey partner gathering — contract finalisation',
   'Contract Review',    '2026-05-02', 'One clause pending legal sign-off',                    'james.park'),

  ('c1000000-0000-0000-0000-000000000007', 'd1000000-0000-0000-0000-000000000006',
   'Boeing Aerospace Forum — post-contract logistics call',
   'Follow Up Call',     '2026-04-18', 'AV and catering BEO submitted to hotel',               'priya.nair'),

  ('c1000000-0000-0000-0000-000000000009', 'd1000000-0000-0000-0000-000000000016',
   'South Beach Wedding — venue tour with couple',
   'Site Visit',         '2026-05-01', 'Couple loved the rooftop — proposal being drafted',    'carlos.mendes'),

  ('c1000000-0000-0000-0000-000000000005', 'd1000000-0000-0000-0000-000000000018',
   'Microsoft Gaming Summit — initial proposal presentation',
   'Proposal Sent',      '2026-05-07', 'Sent 3-scenario pricing — awaiting stakeholder review', 'priya.nair');
