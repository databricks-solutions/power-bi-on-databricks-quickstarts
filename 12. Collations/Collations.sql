-- =====================================================================================================================
-- 1. Create test catalog and schema
-- =====================================================================================================================

CREATE CATALOG IF NOT EXISTS powerbiquickstarts;
USE CATALOG powerbiquickstarts;
CREATE SCHEMA IF NOT EXISTS tpch;
USE SCHEMA tpch;


-- =====================================================================================================================
-- 2. Create test tables with COLLATION
-- =====================================================================================================================

CREATE OR REPLACE TABLE TABLE customer_lcase (
  c_custkey bigint,
  c_name string,
  c_address string,
  c_nationkey string,
  c_phone string,
  c_acctbal decimal(18,2),
  c_mktsegment string COLLATE UTF8_LCASE,
  c_comment string);

INSERT INTO customer_lcase
SELECT * FROM samples.tpch.customer;


-- =====================================================================================================================
-- 3. Cleanup
-- =====================================================================================================================

DROP CATALOG IF EXISTS powerbiquickstarts CASCADE;