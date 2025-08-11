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

CREATE OR REPLACE VIEW orders_transformed AS
SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate, o_orderpriority, o_clerk, o_shippriority
    , max(if(p_container='SM BAG', 1, 0)) AS sm_bag
    , max(if(p_container='MED BAG', 1, 0)) AS med_bag
    , max(if(p_container='LG BAG', 1, 0)) AS lg_bag
FROM orders
    JOIN lineitem on o_orderkey=l_orderkey
    JOIN part on l_partkey=p_partkey
GROUP BY ALL;


-- =====================================================================================================================
-- 3. Cleanup
-- =====================================================================================================================

DROP CATALOG IF EXISTS powerbiquickstarts CASCADE;