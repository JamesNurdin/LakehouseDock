WITH orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_revenue,
        d.d_year,
        p.p_category,
        p.p_brand1,
        s.s_region,
        c.c_nation,
        c.c_region
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE d.d_year = '1995'
      AND p.p_category = 'MFGR#12'
      AND s.s_region = 'ASIA'
)
SELECT
    o.d_year,
    o.p_brand1,
    o.s_region,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    COUNT(*) AS order_count
FROM orders o
GROUP BY o.d_year, o.p_brand1, o.s_region
ORDER BY total_profit DESC
LIMIT 10
