WITH order_dates AS (
    SELECT d_datekey,
           d_year,
           d_date
    FROM dim_date
    WHERE CAST(d_date AS DATE) >= DATE '1997-01-01'
      AND CAST(d_date AS DATE) < DATE '1998-01-01'
),
filtered_lineorder AS (
    SELECT lo_orderkey,
           lo_custkey,
           lo_partkey,
           lo_suppkey,
           lo_revenue,
           lo_supplycost,
           lo_orderdate
    FROM lineorder
    WHERE CAST(lo_orderdate AS VARCHAR) IN (SELECT d_datekey FROM order_dates)
)
SELECT
    od.d_year AS year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM filtered_lineorder lo
JOIN order_dates od
    ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#12'
  AND c.c_region = 'ASIA'
GROUP BY od.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
