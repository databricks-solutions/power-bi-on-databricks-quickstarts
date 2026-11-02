-- =====================================================================================================================
-- 1. Create test catalog
-- =====================================================================================================================

CREATE CATALOG IF NOT EXISTS powerbiquickstarts;
USE CATALOG powerbiquickstarts;



-- =====================================================================================================================
-- 2. Create test schema `tpch` and tables
-- =====================================================================================================================

CREATE SCHEMA IF NOT EXISTS tpch;
USE SCHEMA tpch;

CREATE OR REPLACE TABLE orders AS SELECT * FROM samples.tpch.orders;
CREATE OR REPLACE TABLE customer AS SELECT * FROM samples.tpch.customer;
CREATE OR REPLACE TABLE nation AS SELECT * FROM samples.tpch.nation;
CREATE OR REPLACE TABLE region AS SELECT * FROM samples.tpch.region;

ALTER TABLE orders ADD CONSTRAINT pk_orders PRIMARY KEY(o_orderkey) RELY;
ALTER TABLE customer ADD CONSTRAINT pk_customer PRIMARY KEY(c_custkey) RELY;
ALTER TABLE nation ADD CONSTRAINT pk_nation PRIMARY KEY(n_nationkey) RELY;
ALTER TABLE region ADD CONSTRAINT pk_region PRIMARY KEY(r_regionkey) RELY;

ALTER TABLE orders ADD CONSTRAINT fk_customer FOREIGN KEY(o_custkey) REFERENCES customer NOT ENFORCED RELY;
ALTER TABLE customer ADD CONSTRAINT fk_nation FOREIGN KEY(c_nationkey) REFERENCES nation NOT ENFORCED RELY;
ALTER TABLE nation ADD CONSTRAINT fk_region FOREIGN KEY(n_regionkey) REFERENCES region NOT ENFORCED RELY;

CREATE OR REPLACE VIEW v_orders AS SELECT *, now() as currenttime FROM orders;



-- =====================================================================================================================
-- 3. Cleanup
-- =====================================================================================================================

DROP CATALOG IF EXISTS powerbiquickstarts CASCADE;
