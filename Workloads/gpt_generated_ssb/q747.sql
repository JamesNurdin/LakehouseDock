/*
  Revenue & profit analysis by customer region, part category, and order year
  for the AUTOMOBILE market segment, ASIA suppliers, and orders in 1995.
*/
WITH order_dates AS (
    SELECT
        d_datekey,
        d_year,
        d_date
    FROM dim_date
    WHERE CAST(d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c.c_region                     AS customer_region,
    p.p_category                   AS part_category,
    od.d_year                      AS order_year,
    SUM(lo.lo_revenue)             AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS total_profit,
    AVG(lo.lo_discount)            AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS num_orders
FROM lineorder lo
JOIN customer c   ON lo.lo_custkey = c.c_custkey
JOIN part p       ON lo.lo_partkey = p.p_partkey
JOIN supplier s   ON lo.lo_suppkey = s.s_suppkey
JOIN order_dates od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND s.s_region      = 'ASIA'
GROUP BY c.c_region, p.p_category, od.d_year
HAVING SUM(lo.lo_revenue) > 500000
ORDER BY total_profit DESC
LIMIT 20
