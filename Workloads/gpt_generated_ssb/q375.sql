SELECT
    dim_date.d_year,
    customer.c_region,
    part.p_category,
    supplier.s_region,
    SUM(lineorder.lo_revenue) AS total_revenue,
    SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lineorder.lo_orderkey) AS order_count
FROM lineorder
JOIN dim_date
  ON CAST(lineorder.lo_orderdate AS VARCHAR) = dim_date.d_datekey
JOIN customer
  ON lineorder.lo_custkey = customer.c_custkey
JOIN part
  ON lineorder.lo_partkey = part.p_partkey
JOIN supplier
  ON lineorder.lo_suppkey = supplier.s_suppkey
WHERE dim_date.d_year BETWEEN '1995' AND '1997'
GROUP BY dim_date.d_year, customer.c_region, part.p_category, supplier.s_region
ORDER BY dim_date.d_year, total_profit DESC
