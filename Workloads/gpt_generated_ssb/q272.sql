WITH filtered_dates AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE CAST(d_date AS DATE) BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
)
SELECT
    fd.d_year AS year,
    c.c_region AS customer_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN filtered_dates fd
  ON lo.lo_orderdate = CAST(fd.d_datekey AS INTEGER)
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#12'
  AND p.p_brand1 = 'Brand#45'
  AND s.s_region = 'ASIA'
GROUP BY fd.d_year, c.c_region
ORDER BY total_revenue DESC
LIMIT 100
