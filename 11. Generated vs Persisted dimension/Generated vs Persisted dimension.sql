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

CREATE OR REPLACE TABLE orders AS SELECT * FROM samples.tpch.orders;

CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT
  o_orderdate as date,
  year(o_orderdate) as year,
  month(o_orderdate) as month,
  day(o_orderdate) as day,
  dayofweek(o_orderdate) as day_of_week,
  weekofyear(o_orderdate) as week_of_year,
  quarter(o_orderdate) as quarter
FROM orders;


-- =====================================================================================================================
-- 3. Cleanup
-- =====================================================================================================================

DROP CATALOG IF EXISTS powerbiquickstarts CASCADE;