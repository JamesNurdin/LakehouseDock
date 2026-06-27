SELECT
    d.d_year,
    d.d_month,
    c.c_name,
    c.c_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date d
  ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
  AND p.p_category = 'MFGR#12'
GROUP BY d.d_year, d.d_month, c.c_name, c.c_region
ORDER BY total_profit DESC
LIMIT 10
