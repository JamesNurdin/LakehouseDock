/*
  Analytical query: total revenue, profit and order metrics per supplier region
  and part category for orders placed in the first month of 1994.
*/
WITH order_summary AS (
    SELECT
        s.s_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_extendedprice - lo.lo_supplycost) AS total_profit,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_orderdate BETWEEN 19940101 AND 19940131
    GROUP BY s.s_region, p.p_category
)
SELECT
    s_region,
    p_category,
    total_revenue,
    total_profit,
    distinct_orders,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY s_region ORDER BY total_revenue DESC) AS revenue_rank_in_region
FROM order_summary
ORDER BY total_revenue DESC
LIMIT 20
