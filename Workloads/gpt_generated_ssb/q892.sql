WITH revenue_by_region AS (
    SELECT
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        c.c_mktsegment,
        lo.lo_shipmode,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(DISTINCT lo.lo_orderkey) AS num_orders,
        COUNT(*) AS line_items
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 0
    GROUP BY
        c.c_region,
        s.s_region,
        c.c_mktsegment,
        lo.lo_shipmode
)
SELECT
    customer_region,
    supplier_region,
    c_mktsegment,
    lo_shipmode,
    total_revenue,
    total_profit,
    num_orders,
    line_items,
    -- profit margin expressed as a percentage
    (total_profit / NULLIF(total_revenue, 0)) * 100 AS profit_margin_pct
FROM revenue_by_region
ORDER BY total_revenue DESC
LIMIT 100
