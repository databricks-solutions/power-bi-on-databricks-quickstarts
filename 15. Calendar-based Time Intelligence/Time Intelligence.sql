-- =====================================================================================================================
-- 1. Create test catalog and schema
-- =====================================================================================================================

CREATE CATALOG IF NOT EXISTS powerbiquickstarts;
USE CATALOG powerbiquickstarts;
CREATE SCHEMA IF NOT EXISTS tpch;
USE SCHEMA tpch;


-- =====================================================================================================================
-- 2. Create test tables
-- =====================================================================================================================

CREATE OR REPLACE TABLE region AS SELECT * FROM samples.tpch.region;
CREATE OR REPLACE TABLE nation AS SELECT * FROM samples.tpch.nation;
CREATE OR REPLACE TABLE customer AS SELECT * FROM samples.tpch.customer;
CREATE OR REPLACE TABLE part AS SELECT * FROM samples.tpch.part;
CREATE OR REPLACE TABLE orders AS SELECT * FROM samples.tpch.orders;
CREATE OR REPLACE TABLE lineitem AS SELECT * FROM samples.tpch.lineitem;

CREATE OR REPLACE TABLE calendar AS
WITH cte AS (
  SELECT explode(sequence(DATE '1991-01-01', DATE '2000-12-31')) AS calendar_date
)
SELECT 
    calendar_date as `Date`,
    -- Gregorian attributes
    year(calendar_date)                                                                             AS year,
    quarter(calendar_date)                                                                          AS quarter_of_year,
    format_string('Q%d', quarter(calendar_date))                                                    AS quarter_of_year_label,
    year(calendar_date)*100+quarter(calendar_date)                                                  AS quarter,
    format_string('%d-Q%d', year(calendar_date), quarter(calendar_date))                            AS quarter_label,
    month(calendar_date)                                                                            AS month_of_year,
    year(calendar_date)*100+month(calendar_date)                                                    AS month,
    date_format(calendar_date, 'MMMM')                                                              AS month_of_year_label,
    date_format(calendar_date, 'MMMM yyyy')                                                         AS month_label,
    day(calendar_date)                                                                              AS day_of_month,
    dayofyear(calendar_date)                                                                        AS day_of_year,
    -- ISO week-based attributes
    extract(YEAROFWEEK FROM calendar_date)                                                          AS iso_year,            -- ISO week-year
    weekofyear(calendar_date)                                                                       AS iso_week_of_year,    -- 1–52/53
    format_string('%d-W%02d', extract(YEAROFWEEK FROM calendar_date), weekofyear(calendar_date))    AS iso_week_label,      -- e.g. 2023-W50
    extract(DAYOFWEEK_ISO FROM calendar_date)                                                       AS iso_day_of_week     -- 1=Mon..7=Sun
FROM cte;

-- =====================================================================================================================
-- 3. Cleanup
-- =====================================================================================================================

DROP CATALOG IF EXISTS powerbiquickstarts CASCADE;
