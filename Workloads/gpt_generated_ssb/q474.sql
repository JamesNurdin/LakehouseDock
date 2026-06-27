SELECT
    supplier.s_region,
    part.p_category,
    order_date.d_year AS order_year,
    SUM(lineorder.lo_revenue) AS total_revenue,
    SUM(lineorder.lo_supplycost) AS total_supply_cost,
    SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit
FROM lineorder
JOIN dim_date AS order_date
  ON CAST(lineorder.lo_orderdate AS varchar) = order_date.d_datekey
JOIN dim_date AS commit_date
  ON CAST(lineorder.lo_commitdate AS varchar) = commit_date.d_datekey
JOIN supplier
  ON lineorder.lo_suppkey = supplier.s_suppkey
JOIN part
  ON lineorder.lo_partkey = part.p_partkey
JOIN customer
  ON lineorder.lo_custkey = customer.c_custkey
WHERE CAST(order_date.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
  AND CAST(commit_date.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
  AND customer.c_region = 'ASIA'
GROUP BY supplier.s_region, part.p_category, order_date.d_year
ORDER BY total_revenue DESC
LIMIT 10
