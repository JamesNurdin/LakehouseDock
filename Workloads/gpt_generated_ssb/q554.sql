SELECT
    s.s_region,
    p.p_category,
    d_order.d_year,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN dim_date d_order
    ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
JOIN dim_date d_commit
    ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
JOIN part p
    ON p.p_partkey = lo.lo_partkey
JOIN supplier s
    ON s.s_suppkey = lo.lo_suppkey
JOIN customer c
    ON c.c_custkey = lo.lo_custkey
WHERE CAST(d_order.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
  AND p.p_category = 'MFGR#12'
  AND c.c_region = 'ASIA'
GROUP BY s.s_region, p.p_category, d_order.d_year
ORDER BY total_profit DESC
LIMIT 10
