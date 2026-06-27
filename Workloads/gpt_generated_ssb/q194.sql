WITH lo_agg AS (
    SELECT
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_partkey,
        SUM(lo.lo_revenue) AS revenue,
        SUM(lo.lo_supplycost) AS supply_cost,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    WHERE lo.lo_discount > 5
    GROUP BY lo.lo_custkey, lo.lo_suppkey, lo.lo_partkey
)
SELECT
    s.s_region,
    p.p_category,
    c.c_mktsegment,
    COUNT(*) AS num_orders,
    SUM(lo_agg.revenue) AS total_revenue,
    SUM(lo_agg.supply_cost) AS total_supply_cost,
    SUM(lo_agg.revenue - lo_agg.supply_cost) AS total_profit,
    AVG(lo_agg.avg_discount) AS avg_discount,
    SUM(lo_agg.total_quantity) AS total_quantity
FROM lo_agg
JOIN customer c ON lo_agg.lo_custkey = c.c_custkey
JOIN supplier s ON lo_agg.lo_suppkey = s.s_suppkey
JOIN part p ON lo_agg.lo_partkey = p.p_partkey
WHERE s.s_region = 'ASIA'
  AND p.p_category = 'MFGR#12'
GROUP BY s.s_region, p.p_category, c.c_mktsegment
ORDER BY total_revenue DESC
LIMIT 20
