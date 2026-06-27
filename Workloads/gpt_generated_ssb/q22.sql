SELECT
    od.d_year AS order_year,
    s.s_region AS supplier_region,
    p.p_category AS product_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(cd.d_date AS date), CAST(od.d_date AS date))) AS avg_lead_time_days
FROM lineorder lo
JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
JOIN customer c ON lo.lo_custkey = c.c_custkey
WHERE od.d_year BETWEEN '1994' AND '1996'
  AND lo.lo_discount < 5
GROUP BY od.d_year, s.s_region, p.p_category
ORDER BY od.d_year, s.s_region, p.p_category
