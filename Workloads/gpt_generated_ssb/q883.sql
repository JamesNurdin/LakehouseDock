/*
  Revenue, profit and average lead time per supplier region and part category
  for orders placed in 1995 (ASIA market segment) and part category MFGR#1.
*/
WITH lo_calc AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) AS revenue,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) - lo.lo_supplycost AS profit
    FROM lineorder lo
)
SELECT
    d_o.d_year AS order_year,
    p.p_category,
    s.s_region,
    COUNT(DISTINCT l.lo_orderkey) AS order_cnt,
    SUM(l.revenue) AS total_revenue,
    SUM(l.profit) AS total_profit,
    AVG(date_diff('day', CAST(d_o.d_date AS DATE), CAST(d_c.d_date AS DATE))) AS avg_lead_days
FROM lo_calc l
JOIN dim_date d_o
    ON CAST(d_o.d_datekey AS integer) = l.lo_orderdate
JOIN dim_date d_c
    ON CAST(d_c.d_datekey AS integer) = l.lo_commitdate
JOIN part p
    ON l.lo_partkey = p.p_partkey
JOIN supplier s
    ON l.lo_suppkey = s.s_suppkey
JOIN customer c
    ON l.lo_custkey = c.c_custkey
WHERE d_o.d_year = '1995'
  AND p.p_category = 'MFGR#1'
  AND c.c_region = 'ASIA'
GROUP BY d_o.d_year, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 50
