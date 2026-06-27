SELECT
    s.s_region,
    d_order.d_year,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date d_order
    ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
JOIN dim_date d_commit
    ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1995'
  AND CAST(d_commit.d_date AS date) > DATE '1995-12-31'
GROUP BY s.s_region, d_order.d_year
ORDER BY total_revenue DESC
LIMIT 10
