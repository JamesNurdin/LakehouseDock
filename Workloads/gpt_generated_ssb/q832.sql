SELECT
  order_date.d_year AS order_year,
  customer.c_region,
  part.p_category,
  SUM(lineorder.lo_revenue) AS total_revenue,
  SUM(lineorder.lo_supplycost) AS total_supplycost,
  SUM(lineorder.lo_revenue) - SUM(lineorder.lo_supplycost) AS profit,
  AVG(lineorder.lo_discount) AS avg_discount,
  AVG(date_diff('day', CAST(order_date.d_date AS DATE), CAST(commit_date.d_date AS DATE))) AS avg_lead_days,
  COUNT(DISTINCT lineorder.lo_orderkey) AS distinct_orders
FROM lineorder
JOIN dim_date AS order_date
  ON CAST(order_date.d_datekey AS INTEGER) = lineorder.lo_orderdate
JOIN dim_date AS commit_date
  ON CAST(commit_date.d_datekey AS INTEGER) = lineorder.lo_commitdate
JOIN customer
  ON lineorder.lo_custkey = customer.c_custkey
JOIN part
  ON lineorder.lo_partkey = part.p_partkey
JOIN supplier
  ON lineorder.lo_suppkey = supplier.s_suppkey
WHERE order_date.d_year = '1995'
  AND customer.c_region = 'AMERICA'
  AND part.p_category = 'MFGR#12'
GROUP BY order_date.d_year, customer.c_region, part.p_category
ORDER BY profit DESC
LIMIT 10
