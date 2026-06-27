SELECT
    c.c_region,
    od.d_year,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN dim_date od
    ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
WHERE od.d_year = '1995'
GROUP BY c.c_region, od.d_year, p.p_category
ORDER BY total_revenue DESC
