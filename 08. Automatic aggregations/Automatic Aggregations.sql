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

-- Create test tables based on samples.tpch dataset
CREATE OR REPLACE TABLE region AS SELECT * FROM samples.tpch.region;
CREATE OR REPLACE TABLE nation AS SELECT * FROM samples.tpch.nation;
CREATE OR REPLACE TABLE customer AS SELECT * FROM samples.tpch.customer;
CREATE OR REPLACE TABLE orders AS SELECT * FROM samples.tpch.orders;

CREATE OR REPLACE VIEW v_nation AS 
SELECT *, now() as currenttime FROM nation;


-- =====================================================================================================================
-- 3. Cleanup
-- =====================================================================================================================

DROP CATALOG IF EXISTS powerbiquickstarts CASCADE;