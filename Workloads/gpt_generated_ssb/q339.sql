SELECT
    od.d_year AS order_year,
    p.p_category,
    s.s_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    COUNT(*) AS order_line_count,
    AVG(lo.lo_quantity) AS avg_quantity
FROM lineorder lo
JOIN dim_date od ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
JOIN dim_date cd ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE cd.d_holidayfl = 'Y'
GROUP BY od.d_year, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 10
