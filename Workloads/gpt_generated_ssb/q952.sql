WITH lineorder_agg AS (
    SELECT
        lo.lo_partkey,
        lo.lo_suppkey,
        SUM(lo.lo_revenue) AS sum_revenue,
        SUM(lo.lo_supplycost) AS sum_supplycost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS sum_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS line_count
    FROM lineorder lo
    GROUP BY lo.lo_partkey, lo.lo_suppkey
)
SELECT
    s.s_region,
    p.p_category,
    p.p_brand1,
    la.sum_revenue AS total_revenue,
    la.sum_supplycost AS total_supply_cost,
    la.sum_profit AS total_profit,
    la.avg_discount AS avg_discount,
    la.line_count AS order_line_count
FROM lineorder_agg la
JOIN part p ON la.lo_partkey = p.p_partkey
JOIN supplier s ON la.lo_suppkey = s.s_suppkey
WHERE s.s_region = 'ASIA'
  AND p.p_size > 10
ORDER BY la.sum_revenue DESC
LIMIT 10
