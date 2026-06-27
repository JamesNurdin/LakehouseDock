SELECT
    d.d_year AS year,
    c.c_region AS region,
    p.p_category AS category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    SUM(lo.lo_revenue - lo.lo_supplycost) / SUM(lo.lo_revenue) AS profit_margin,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN dim_date d
    ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE s.s_region = 'ASIA'
  AND p.p_category = 'MFGR#12'
  AND d.d_year = '1995'
GROUP BY d.d_year, c.c_region, p.p_category
ORDER BY d.d_year, c.c_region, p.p_category
