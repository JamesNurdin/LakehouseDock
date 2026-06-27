SELECT
    sup.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
FROM lineorder lo
JOIN dim_date d ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
JOIN supplier sup ON lo.lo_suppkey = sup.s_suppkey
JOIN part p ON lo.lo_partkey = p.p_partkey
WHERE d.d_year = '1997'
  AND lo.lo_discount > 5
  AND lo.lo_orderpriority = '1-URGENT'
GROUP BY sup.s_region, p.p_category
ORDER BY total_revenue DESC
