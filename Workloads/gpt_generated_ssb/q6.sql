SELECT
    s.s_region,
    p.p_brand1,
    d_order.d_year AS order_year,
    AVG(date_diff('day', CAST(d_order.d_date AS DATE), CAST(d_commit.d_date AS DATE))) AS avg_days_to_commit,
    SUM(lo.lo_revenue) AS total_revenue
FROM lineorder lo
JOIN dim_date d_order
  ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN dim_date d_commit
  ON CAST(d_commit.d_datekey AS INTEGER) = lo.lo_commitdate
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE d_order.d_year = '1995'
GROUP BY s.s_region, p.p_brand1, d_order.d_year
ORDER BY total_revenue DESC
