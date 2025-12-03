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


-- =====================================================================================================================
-- 3. Cleanup
-- =====================================================================================================================

DROP CATALOG IF EXISTS powerbiquickstarts CASCADE;
