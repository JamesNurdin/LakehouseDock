SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    od.d_year AS order_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    AVG(date_diff('day', DATE(od.d_date), DATE(cd.d_date))) AS avg_lead_time_days,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1995'
GROUP BY
    c.c_region,
    s.s_region,
    p.p_category,
    od.d_year
ORDER BY total_revenue DESC
LIMIT 100
