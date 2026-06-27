SELECT
    CONCAT(dd.d_year, '-', c.c_region) AS year_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date dd
    ON CAST(lo.lo_orderdate AS varchar) = dd.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE CAST(dd.d_date AS date) BETWEEN DATE '1992-01-01' AND DATE '1997-12-31'
  AND p.p_category = 'MFGR#12'
  AND s.s_region = 'ASIA'
GROUP BY CONCAT(dd.d_year, '-', c.c_region)
ORDER BY total_revenue DESC
