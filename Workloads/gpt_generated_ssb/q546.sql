WITH lo_metrics AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_orderdate,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
    WHERE lo.lo_quantity > 0
)
SELECT
    c.c_region,
    c.c_nation,
    c.c_mktsegment,
    p.p_category,
    s.s_nation,
    SUM(lo_metrics.lo_revenue) AS total_revenue,
    SUM(lo_metrics.profit) AS total_profit,
    COUNT(*) AS lineorder_count
FROM lo_metrics
JOIN customer c ON lo_metrics.lo_custkey = c.c_custkey
JOIN part p ON lo_metrics.lo_partkey = p.p_partkey
JOIN supplier s ON lo_metrics.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    c.c_nation,
    c.c_mktsegment,
    p.p_category,
    s.s_nation
ORDER BY total_revenue DESC
LIMIT 100
