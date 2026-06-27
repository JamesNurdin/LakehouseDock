WITH filtered_orders AS (
    SELECT
        lo_orderdate,
        lo_suppkey,
        lo_partkey,
        lo_custkey,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_quantity,
        lo_extendedprice,
        lo_ordertotalprice,
        lo_tax
    FROM lineorder
    WHERE lo_quantity >= 30
),
order_dates AS (
    SELECT
        d_datekey,
        d_year,
        d_date
    FROM dim_date
    WHERE d_year BETWEEN '1992' AND '1997'
),
customer_filtered AS (
    SELECT
        c_custkey,
        c_region,
        c_nation
    FROM customer
    WHERE c_region = 'ASIA'
),
part_filtered AS (
    SELECT
        p_partkey,
        p_brand1,
        p_category
    FROM part
    WHERE p_category = 'MFGR#12'
)
SELECT
    od.d_year,
    s.s_nation,
    pf.p_brand1,
    SUM(fo.lo_revenue) AS total_revenue,
    SUM(fo.lo_supplycost) AS total_supplycost,
    SUM(fo.lo_revenue - fo.lo_supplycost) AS total_profit,
    AVG(fo.lo_discount) AS avg_discount,
    COUNT(DISTINCT fo.lo_orderdate) AS distinct_order_dates
FROM filtered_orders fo
JOIN order_dates od ON fo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN customer_filtered cf ON fo.lo_custkey = cf.c_custkey
JOIN part_filtered pf ON fo.lo_partkey = pf.p_partkey
JOIN supplier s ON fo.lo_suppkey = s.s_suppkey
GROUP BY od.d_year, s.s_nation, pf.p_brand1
ORDER BY od.d_year, s.s_nation, pf.p_brand1
