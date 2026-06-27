WITH supplier_metrics AS (
    SELECT
        s.s_region,
        s.s_nation,
        lo.lo_shipmode,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_quantity) AS avg_quantity,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_discount < 5
    GROUP BY s.s_region, s.s_nation, lo.lo_shipmode
)
SELECT
    s_region,
    s_nation,
    lo_shipmode,
    total_revenue,
    total_profit,
    avg_quantity,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY s_region ORDER BY total_revenue DESC) AS region_rank
FROM supplier_metrics
ORDER BY total_revenue DESC
LIMIT 10
