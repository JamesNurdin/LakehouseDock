SELECT
    od.d_year AS order_year,
    c.c_region AS customer_region,
    p.p_category AS product_category,
    SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS total_net_sales,
    SUM((lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) - (lo.lo_supplycost * lo.lo_quantity)) AS total_profit,
    AVG(date_diff('day', CAST(od.d_date AS DATE), CAST(cd.d_date AS DATE))) AS avg_days_to_commit,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE c.c_region = 'ASIA'
  AND od.d_year = '1995'
GROUP BY od.d_year, c.c_region, p.p_category
ORDER BY od.d_year, c.c_region, p.p_category
