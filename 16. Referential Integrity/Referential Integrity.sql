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

CREATE OR REPLACE TABLE part AS SELECT * FROM samples.tpch.part;
CREATE OR REPLACE TABLE supplier AS SELECT * FROM samples.tpch.supplier;
CREATE OR REPLACE TABLE lineitem AS SELECT * FROM samples.tpch.lineitem;

ALTER TABLE part ALTER COLUMN p_partkey SET NOT NULL;
ALTER TABLE supplier ALTER COLUMN s_suppkey SET NOT NULL;

ALTER TABLE part ADD CONSTRAINT pk_part PRIMARY KEY(p_partkey) RELY;
ALTER TABLE supplier ADD CONSTRAINT pk_supplier PRIMARY KEY(s_suppkey) RELY;

ALTER TABLE lineitem ADD CONSTRAINT fk_parts FOREIGN KEY(l_partkey) REFERENCES part NOT ENFORCED RELY;
ALTER TABLE lineitem ADD CONSTRAINT fk_supplier FOREIGN KEY(l_suppkey) REFERENCES supplier NOT ENFORCED RELY;

CREATE OR REPLACE VIEW v_lineitem AS SELECT *, now() as currenttime FROM lineitem;

ALTER TABLE lineitem CLUSTER BY (l_suppkey, l_partkey);
OPTIMIZE lineitem FULL;


-- =====================================================================================================================
-- 2. Create test schema `tpch_nointegrity` and tables
-- =====================================================================================================================

CREATE SCHEMA IF NOT EXISTS tpch_nointegrity;
USE SCHEMA tpch_nointegrity;

CREATE OR REPLACE TABLE part 
AS SELECT
    CAST(p_partkey AS INT) AS p_partkey,
    p_name,
    p_mfgr,
    p_brand,
    p_type,
    p_size,
    p_container,
    p_retailprice,
    p_comment
FROM samples.tpch.part;

CREATE OR REPLACE TABLE supplier
AS SELECT
    CAST(s_suppkey AS INT) AS s_suppkey,
    s_name,
    s_address,
    s_nationkey,
    s_phone,
    s_acctbal,
    s_comment
FROM samples.tpch.supplier;

CREATE OR REPLACE TABLE lineitem AS SELECT * FROM samples.tpch.lineitem;

ALTER TABLE part ALTER COLUMN p_partkey SET NOT NULL;
ALTER TABLE supplier ALTER COLUMN s_suppkey SET NOT NULL;

ALTER TABLE part ADD CONSTRAINT pk_part PRIMARY KEY(p_partkey) RELY;
ALTER TABLE supplier ADD CONSTRAINT pk_supplier PRIMARY KEY(s_suppkey) RELY;

ALTER TABLE lineitem ADD CONSTRAINT fk_parts FOREIGN KEY(l_partkey) REFERENCES part NOT ENFORCED RELY;
ALTER TABLE lineitem ADD CONSTRAINT fk_supplier FOREIGN KEY(l_suppkey) REFERENCES supplier NOT ENFORCED RELY;

CREATE OR REPLACE VIEW v_lineitem AS SELECT *, now() as currenttime FROM lineitem;

ALTER TABLE lineitem CLUSTER BY (l_suppkey, l_partkey);
OPTIMIZE lineitem FULL; 


-- =====================================================================================================================
-- 3. Cleanup
-- =====================================================================================================================

DROP CATALOG IF EXISTS powerbiquickstarts CASCADE;
