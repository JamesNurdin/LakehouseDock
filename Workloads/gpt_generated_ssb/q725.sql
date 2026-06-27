WITH part_filtered AS (
    SELECT p_partkey, p_category
    FROM part
    WHERE p_category = 'MFGR#1'
),
date_filtered AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE d_year = '1995'
)
SELECT
    od.d_year AS year,
    s.s_region AS supplier_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    SUM(CASE WHEN c.c_mktsegment = 'AUTOMOBILE' THEN lo.lo_revenue ELSE 0 END) AS auto_revenue,
    SUM(CASE WHEN c.c_mktsegment = 'AUTOMOBILE' THEN lo.lo_revenue ELSE 0 END) / SUM(lo.lo_revenue) AS auto_revenue_pct
FROM lineorder lo
JOIN part_filtered p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN date_filtered od
  ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
GROUP BY od.d_year, s.s_region
ORDER BY total_revenue DESC
LIMIT 20
