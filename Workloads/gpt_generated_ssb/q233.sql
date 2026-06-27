SELECT
    s.s_region,
    order_date.d_year,
    SUM(lo.lo_revenue) AS total_revenue,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN dim_date order_date
    ON CAST(lo.lo_orderdate AS varchar) = order_date.d_datekey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
WHERE order_date.d_year = '1995'
  AND p.p_category = 'MFGR#12'
GROUP BY s.s_region, order_date.d_year
ORDER BY total_revenue DESC
LIMIT 10
