/*
  Analytical query: total revenue, supply‑cost, profit and average discount
  by customer region and order year for parts in category 'MFGR#1'.
  The query joins the lineorder fact table to all dimension tables using
  the only permitted join keys, filters on a range of order years, and
  ensures the commit date falls in the same year as the order date.
*/
SELECT
    c.c_region               AS region,
    d.d_year                 AS order_year,
    SUM(lo.lo_revenue)       AS total_revenue,
    SUM(lo.lo_supplycost)    AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount)      AS avg_discount,
    COUNT(*)                 AS order_count
FROM lineorder lo
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN dim_date d
  ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN dim_date cd
  ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#1'
  AND d.d_year BETWEEN '1992' AND '1997'
  AND cd.d_year = d.d_year
GROUP BY c.c_region, d.d_year
ORDER BY c.c_region, d.d_year
