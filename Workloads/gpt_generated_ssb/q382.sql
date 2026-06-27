/*
  Analytical query for the SSB benchmark using Trino syntax.
  It reports total revenue, profit, quantity and average discount
  by calendar year, customer nation and part category for orders
  placed between 1995‑01‑01 and 1997‑12‑31.
*/
WITH filtered_orders AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_orderdate,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
)
SELECT
    fo.d_year                     AS year,
    c.c_nation                     AS nation,
    p.p_category                   AS category,
    SUM(fo.lo_revenue)             AS total_revenue,
    SUM(fo.lo_revenue - fo.lo_supplycost) AS total_profit,
    SUM(fo.lo_quantity)            AS total_quantity,
    AVG(fo.lo_discount)            AS avg_discount
FROM filtered_orders fo
JOIN customer c
    ON fo.lo_custkey = c.c_custkey
JOIN part p
    ON fo.lo_partkey = p.p_partkey
GROUP BY fo.d_year, c.c_nation, p.p_category
ORDER BY fo.d_year, c.c_nation, p.p_category
