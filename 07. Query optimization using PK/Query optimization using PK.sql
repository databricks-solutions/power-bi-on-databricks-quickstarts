-- =====================================================================================================================
-- 1. Create test catalog and schema
-- =====================================================================================================================

CREATE CATALOG IF NOT EXISTS powerbiquickstarts;
USE CATALOG powerbiquickstarts;
CREATE SCHEMA IF NOT EXISTS tpch;
USE SCHEMA tpch;

-- =====================================================================================================================
-- 2. Create test tables without PK constraints
-- =====================================================================================================================

-- Create test tables based on samples.tpch dataset
CREATE OR REPLACE TABLE lineitem AS SELECT * FROM samples.tpch.lineitem;
CREATE OR REPLACE TABLE orders AS SELECT * FROM samples.tpch.orders;
CREATE OR REPLACE TABLE part AS SELECT * FROM samples.tpch.part;
CREATE OR REPLACE TABLE supplier AS SELECT * FROM samples.tpch.supplier;
CREATE OR REPLACE TABLE customer AS SELECT * FROM samples.tpch.customer;
CREATE OR REPLACE TABLE nation AS SELECT * FROM samples.tpch.nation;
CREATE OR REPLACE TABLE region AS SELECT * FROM samples.tpch.region;

-- Drop any PK if exists
ALTER TABLE orders DROP PRIMARY KEY IF EXISTS;
ALTER TABLE part DROP PRIMARY KEY IF EXISTS;
ALTER TABLE supplier DROP PRIMARY KEY IF EXISTS;
ALTER TABLE customer DROP PRIMARY KEY IF EXISTS;
ALTER TABLE nation DROP PRIMARY KEY IF EXISTS;
ALTER TABLE region DROP PRIMARY KEY IF EXISTS;

CREATE OR REPLACE VIEW v_lineitems as
SELECT 
    l_orderkey, l_partkey, l_suppkey, l_quantity, l_tax, l_discount
    , o_orderkey, o_custkey, o_totalprice, o_orderstatus, o_orderdate, o_orderpriority
FROM lineitem
    LEFT JOIN orders ON l_orderkey=o_orderkey;


-- =====================================================================================================================
-- 3. Run sample report in Power BI Desktop
-- =====================================================================================================================


-- =====================================================================================================================
-- 4. Create PK RELY constraints
-- =====================================================================================================================

-- Re-create test tables based on samples.tpch dataset
CREATE OR REPLACE TABLE lineitem AS SELECT * FROM samples.tpch.lineitem;
CREATE OR REPLACE TABLE orders AS SELECT * FROM samples.tpch.orders;
CREATE OR REPLACE TABLE part AS SELECT * FROM samples.tpch.part;
CREATE OR REPLACE TABLE supplier AS SELECT * FROM samples.tpch.supplier;
CREATE OR REPLACE TABLE customer AS SELECT * FROM samples.tpch.customer;
CREATE OR REPLACE TABLE nation AS SELECT * FROM samples.tpch.nation;
CREATE OR REPLACE TABLE region AS SELECT * FROM samples.tpch.region;

-- Define primary keys using RELY keyword
ALTER TABLE orders ALTER COLUMN o_orderkey SET NOT NULL;
ALTER TABLE orders ADD PRIMARY KEY (o_orderkey) RELY;
ALTER TABLE part ALTER COLUMN p_partkey SET NOT NULL;
ALTER TABLE part ADD PRIMARY KEY (p_partkey) RELY;
ALTER TABLE supplier ALTER COLUMN s_suppkey SET NOT NULL;
ALTER TABLE supplier ADD PRIMARY KEY (s_suppkey) RELY;
ALTER TABLE customer ALTER COLUMN c_custkey SET NOT NULL;
ALTER TABLE customer ADD PRIMARY KEY (c_custkey) RELY;
ALTER TABLE nation ALTER COLUMN n_nationkey SET NOT NULL;
ALTER TABLE nation ADD PRIMARY KEY (n_nationkey) RELY;
ALTER TABLE region ALTER COLUMN r_regionkey SET NOT NULL;
ALTER TABLE region ADD PRIMARY KEY (r_regionkey) RELY;


-- =====================================================================================================================
-- 5. Run sample report in Power BI Desktop
-- =====================================================================================================================


-- =====================================================================================================================
-- 6. Cleanup
-- =====================================================================================================================

DROP CATALOG IF EXISTS powerbiquickstarts CASCADE;