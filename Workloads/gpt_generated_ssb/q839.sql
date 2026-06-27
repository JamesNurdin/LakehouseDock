SELECT
    order_date_dim.d_year AS order_year,
    supplier.s_region AS supplier_region,
    customer.c_region AS customer_region,
    SUM(lineorder.lo_revenue) AS total_revenue,
    SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    AVG(lineorder.lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM lineorder
JOIN dim_date AS order_date_dim
  ON CAST(order_date_dim.d_datekey AS integer) = lineorder.lo_orderdate
JOIN dim_date AS commit_date_dim
  ON CAST(commit_date_dim.d_datekey AS integer) = lineorder.lo_commitdate
JOIN customer
  ON lineorder.lo_custkey = customer.c_custkey
JOIN part
  ON lineorder.lo_partkey = part.p_partkey
JOIN supplier
  ON lineorder.lo_suppkey = supplier.s_suppkey
WHERE lineorder.lo_shipmode = 'AIR'
  AND part.p_size > 10
  AND commit_date_dim.d_date > order_date_dim.d_date
  AND order_date_dim.d_year = '1995'
GROUP BY order_date_dim.d_year, supplier.s_region, customer.c_region
ORDER BY total_revenue DESC
LIMIT 20
