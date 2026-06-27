WITH filtered_lo AS (
    SELECT
        lo.lo_suppkey,
        lo.lo_partkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
    WHERE lo.lo_quantity > 30
      AND lo.lo_shipmode = 'AIR'
),
agg AS (
    SELECT
        s.s_region,
        p.p_category,
        SUM(fl.profit) AS total_profit,
        SUM(fl.lo_revenue) AS total_revenue,
        SUM(fl.lo_supplycost) AS total_supply_cost,
        COUNT(*) AS order_line_count,
        AVG(fl.lo_discount) AS avg_discount
    FROM filtered_lo fl
    JOIN part p ON fl.lo_partkey = p.p_partkey
    JOIN supplier s ON fl.lo_suppkey = s.s_suppkey
    GROUP BY s.s_region, p.p_category
)
SELECT
    a.s_region,
    a.p_category,
    a.total_profit,
    a.total_revenue,
    a.total_supply_cost,
    a.order_line_count,
    a.avg_discount,
    RANK() OVER (ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.total_profit DESC
LIMIT 10
