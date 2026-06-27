WITH agg AS (
    SELECT
        s.s_region,
        s.s_nation,
        lo.lo_orderpriority,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        SUM(lo.lo_quantity) AS total_quantity,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
    FROM lineorder lo
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_shipmode = 'AIR'
    GROUP BY s.s_region, s.s_nation, lo.lo_orderpriority
)
SELECT
    s_region,
    s_nation,
    lo_orderpriority,
    total_revenue,
    total_supplycost,
    total_profit,
    avg_discount,
    total_quantity,
    distinct_orders,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 100
