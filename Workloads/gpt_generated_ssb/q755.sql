/*
  Total profit by customer region and part brand for US customers.
  Demonstrates joins, a CTE with a derived expression, filtering, grouping,
  aggregation, ordering and a LIMIT.
*/
WITH order_profit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
)
SELECT
    c.c_region,
    p.p_brand1,
    SUM(op.profit) AS total_profit,
    AVG(op.profit) AS avg_profit,
    COUNT(DISTINCT op.lo_orderkey) AS distinct_orders
FROM order_profit op
JOIN customer c ON op.lo_custkey = c.c_custkey
JOIN part p ON op.lo_partkey = p.p_partkey
WHERE c.c_nation = 'UNITED STATES'
GROUP BY c.c_region, p.p_brand1
ORDER BY total_profit DESC
LIMIT 20
