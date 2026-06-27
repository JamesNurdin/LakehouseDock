/*
  Analytical query on the SSB benchmark using the allowed tables and join rules.
  It shows, for the year 1995, how revenue, profit and order‑to‑commit lead‑time
  vary by product category and customer region.
*/
WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_orderdate,
        lo.lo_commitdate,
        d_order.d_year               AS order_year,
        d_order.d_date               AS order_date,
        d_commit.d_date              AS commit_date,
        p.p_category                 AS p_category,
        c.c_region                   AS c_region
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1995'
)
SELECT
    order_year,
    p_category,
    c_region,
    COUNT(DISTINCT lo_orderkey)                                     AS num_orders,
    SUM(lo_quantity)                                                AS total_quantity,
    SUM(lo_revenue)                                                 AS total_revenue,
    SUM(lo_supplycost)                                              AS total_supplycost,
    SUM(lo_revenue - lo_supplycost)                                 AS total_profit,
    AVG(date_diff('day', CAST(order_date AS DATE), CAST(commit_date AS DATE)))
                                                                     AS avg_days_to_commit
FROM order_details
GROUP BY order_year, p_category, c_region
ORDER BY total_revenue DESC
LIMIT 20
