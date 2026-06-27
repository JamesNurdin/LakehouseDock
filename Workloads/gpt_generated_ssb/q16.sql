SELECT
    s.s_region,
    p.p_category,
    d.d_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN dim_date d
    ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
WHERE d.d_year = '1997'
GROUP BY s.s_region, p.p_category, d.d_year
ORDER BY total_profit DESC
