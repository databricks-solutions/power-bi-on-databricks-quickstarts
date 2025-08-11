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

CREATE OR REPLACE TABLE nation AS SELECT * FROM samples.tpch.nation;
CREATE OR REPLACE TABLE customer AS SELECT * FROM samples.tpch.customer;
CREATE OR REPLACE TABLE orders AS SELECT * FROM samples.tpch.orders;
CREATE OR REPLACE TABLE lineitem AS SELECT * FROM samples.tpch.lineitem;

CREATE OR REPLACE TABLE lineitem_by_nation_agg AS
SELECT
  `n_nationkey`
  , min(`l_shipdate`) as `EarliestShipdate`
  , sum(`l_discount`) as `SumofDiscount`
  , sum(`l_quantity`) as `SumOfQuantity`
FROM `samples`.`tpch`.`lineitem` 
  INNER JOIN `samples`.`tpch`.`orders` on `l_orderkey` = `o_orderkey`
  INNER JOIN `samples`.`tpch`.`customer` on `o_custkey` = `c_custkey`
  INNER JOIN `samples`.`tpch`.`nation` on `c_nationkey` = `n_nationkey`
GROUP BY ALL;


-- =====================================================================================================================
-- 3. Cleanup
-- =====================================================================================================================

DROP CATALOG IF EXISTS powerbiquickstarts CASCADE;