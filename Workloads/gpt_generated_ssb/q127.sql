WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        c.c_region,
        p.p_category,
        s.s_region AS supplier_region,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE p.p_category = 'MFGR#12'
      AND s.s_region = 'ASIA'
      AND CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
)
SELECT
    d_year,
    c_region,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM order_data
GROUP BY d_year, c_region
ORDER BY total_profit DESC
LIMIT 50
