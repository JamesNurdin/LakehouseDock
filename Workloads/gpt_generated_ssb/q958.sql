WITH agg AS (
    SELECT
        c.c_region AS customer_region,
        c.c_mktsegment AS market_segment,
        s.s_region AS supplier_region,
        lo.lo_orderpriority AS order_priority,
        lo.lo_shipmode AS ship_mode,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_region = 'ASIA'
      AND s.s_region = 'ASIA'
    GROUP BY
        c.c_region,
        c.c_mktsegment,
        s.s_region,
        lo.lo_orderpriority,
        lo.lo_shipmode
)
SELECT
    customer_region,
    market_segment,
    supplier_region,
    order_priority,
    ship_mode,
    total_revenue,
    total_supplycost,
    total_profit,
    avg_discount,
    distinct_orders,
    RANK() OVER (PARTITION BY market_segment ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 20
