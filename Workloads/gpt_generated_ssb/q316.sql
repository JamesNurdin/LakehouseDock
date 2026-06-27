SELECT
    d.d_year AS year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    s.s_region AS supplier_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date d
    ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1997'
  AND c.c_mktsegment = 'AUTOMOBILE'
GROUP BY d.d_year, c.c_region, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 100
