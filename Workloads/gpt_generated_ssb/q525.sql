SELECT
    order_date.d_year AS order_year,
    supplier.s_region AS supplier_region,
    SUM(lineorder.lo_revenue) AS total_revenue,
    SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    SUM(lineorder.lo_quantity) AS total_quantity,
    AVG(lineorder.lo_discount) AS avg_discount,
    COUNT(DISTINCT lineorder.lo_orderkey) AS order_cnt
FROM lineorder
JOIN dim_date AS order_date
    ON CAST(order_date.d_datekey AS INTEGER) = lineorder.lo_orderdate
JOIN dim_date AS commit_date
    ON CAST(commit_date.d_datekey AS INTEGER) = lineorder.lo_commitdate
JOIN part
    ON lineorder.lo_partkey = part.p_partkey
JOIN supplier
    ON lineorder.lo_suppkey = supplier.s_suppkey
JOIN customer
    ON lineorder.lo_custkey = customer.c_custkey
WHERE order_date.d_year = '1995'
  AND part.p_category = 'MFGR#12'
  AND customer.c_region = 'ASIA'
  AND CAST(commit_date.d_datekey AS INTEGER) > CAST(order_date.d_datekey AS INTEGER)
GROUP BY order_date.d_year, supplier.s_region
ORDER BY total_revenue DESC
LIMIT 10
