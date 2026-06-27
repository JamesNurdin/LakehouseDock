/*
  Analytical query on the SSB schema using Trino syntax.
  It reports revenue, profit, average discount and quantity by customer region,
  nation, order year and part category, filtered to a specific part category,
  supplier region and commit‑year.
*/
WITH order_dates AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_year   AS order_year,
        d_commit.d_year  AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
)
SELECT
    c.c_region,
    c.c_nation,
    od.order_year,
    p.p_category,
    SUM(od.lo_revenue)                         AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost)      AS total_profit,
    AVG(od.lo_discount)                        AS avg_discount,
    SUM(od.lo_quantity)                        AS total_quantity
FROM order_dates od
JOIN customer c   ON od.lo_custkey = c.c_custkey
JOIN part p       ON od.lo_partkey = p.p_partkey
JOIN supplier s   ON od.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#12'
  AND s.s_region   = 'ASIA'
  AND od.commit_year = '1994'
GROUP BY
    c.c_region,
    c.c_nation,
    od.order_year,
    p.p_category
ORDER BY total_revenue DESC
LIMIT 10
