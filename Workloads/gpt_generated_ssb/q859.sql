SELECT
    d.d_year,
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN dim_date d
    ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE d.d_year = '1994'
GROUP BY d.d_year, c.c_region, s.s_region, p.p_category
ORDER BY total_profit DESC
LIMIT 20
