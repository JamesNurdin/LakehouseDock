SELECT
    s.s_region,
    p.p_brand1,
    d.d_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(*) AS line_count
FROM lineorder lo
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN dim_date d
    ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND d.d_year = '1995'
  AND p.p_size > 10
GROUP BY s.s_region, p.p_brand1, d.d_year
ORDER BY total_revenue DESC
LIMIT 20
