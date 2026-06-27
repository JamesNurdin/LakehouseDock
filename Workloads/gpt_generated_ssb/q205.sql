SELECT
    customer.c_region,
    supplier.s_region,
    od.d_year,
    SUM(lineorder.lo_revenue) AS total_revenue,
    SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lineorder.lo_orderkey) AS order_count,
    AVG(lineorder.lo_commitdate - lineorder.lo_orderdate) AS avg_lead_days
FROM lineorder
JOIN dim_date AS od
    ON CAST(lineorder.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN dim_date AS cd
    ON CAST(lineorder.lo_commitdate AS VARCHAR) = cd.d_datekey
JOIN customer
    ON lineorder.lo_custkey = customer.c_custkey
JOIN part
    ON lineorder.lo_partkey = part.p_partkey
JOIN supplier
    ON lineorder.lo_suppkey = supplier.s_suppkey
WHERE od.d_year = '1997'
  AND part.p_category = 'MFGR#1'
  AND supplier.s_region = 'ASIA'
  AND customer.c_mktsegment = 'AUTOMOBILE'
GROUP BY
    customer.c_region,
    supplier.s_region,
    od.d_year
ORDER BY total_profit DESC
LIMIT 10
