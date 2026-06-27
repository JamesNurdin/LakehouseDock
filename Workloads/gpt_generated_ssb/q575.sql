SELECT
    d_order.d_year,
    d_order.d_month,
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(d_order.d_date AS DATE), CAST(d_commit.d_date AS DATE))) AS avg_days_to_commit,
    COUNT(*) AS order_cnt
FROM lineorder lo
JOIN dim_date d_order
  ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN dim_date d_commit
  ON CAST(d_commit.d_datekey AS INTEGER) = lo.lo_commitdate
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND lo.lo_shipmode = 'AIR'
  AND d_order.d_year BETWEEN '1993' AND '1997'
GROUP BY d_order.d_year, d_order.d_month, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20
