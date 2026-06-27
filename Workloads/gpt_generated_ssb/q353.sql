SELECT
    dim_date.d_year,
    customer.c_region,
    part.p_category,
    SUM(lineorder.lo_revenue) AS total_revenue,
    SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lineorder.lo_orderkey) AS order_count
FROM lineorder
JOIN dim_date
    ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS integer)
JOIN customer
    ON lineorder.lo_custkey = customer.c_custkey
JOIN part
    ON lineorder.lo_partkey = part.p_partkey
JOIN supplier
    ON lineorder.lo_suppkey = supplier.s_suppkey
WHERE dim_date.d_year = '1997'
  AND customer.c_region = 'ASIA'
  AND part.p_category = 'MFGR#12'
  AND supplier.s_region = 'ASIA'
GROUP BY dim_date.d_year, customer.c_region, part.p_category
ORDER BY total_revenue DESC
LIMIT 10
