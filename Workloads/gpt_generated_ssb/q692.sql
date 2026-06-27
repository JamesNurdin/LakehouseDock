/*
  Analytical query for the SSB benchmark.
  It aggregates revenue, profit, discount and average lead‑time (days between order and commit)
  by order year, customer region, part category and supplier region for the year 1995.
*/
WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_discount,
        d_order.d_year,
        d_order.d_date   AS order_date,
        d_commit.d_date  AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
    WHERE DATE(d_order.d_date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    od.d_year                         AS order_year,
    c.c_region                        AS customer_region,
    p.p_category                      AS part_category,
    s.s_region                        AS supplier_region,
    SUM(od.lo_revenue)                AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost - od.lo_tax) AS total_profit,
    AVG(od.lo_discount)               AS avg_discount,
    AVG(date_diff('day', DATE(od.order_date), DATE(od.commit_date))) AS avg_days_to_commit
FROM order_dates od
JOIN customer c   ON od.lo_custkey = c.c_custkey
JOIN part p       ON od.lo_partkey = p.p_partkey
JOIN supplier s   ON od.lo_suppkey = s.s_suppkey
GROUP BY od.d_year, c.c_region, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 100
