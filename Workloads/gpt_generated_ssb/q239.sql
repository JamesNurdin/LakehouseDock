WITH order_dim AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE d_year = '1997'
)
SELECT
    s.s_region,
    p.p_category,
    od.d_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_extendedprice) AS total_extendedprice,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_extendedprice - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN order_dim od ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
JOIN customer c ON lo.lo_custkey = c.c_custkey
WHERE p.p_category = 'MFGR#1'
GROUP BY s.s_region, p.p_category, od.d_year
ORDER BY total_revenue DESC
LIMIT 10
