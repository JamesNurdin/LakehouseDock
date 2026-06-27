WITH order_metrics AS (
    SELECT
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        (lo_revenue - lo_supplycost) AS profit,
        lo_quantity,
        lo_discount
    FROM lineorder
),
region_agg AS (
    SELECT
        s.s_region,
        s.s_nation,
        s.s_city,
        COUNT(*) AS order_count,
        SUM(o.lo_revenue) AS total_revenue,
        SUM(o.lo_supplycost) AS total_supply_cost,
        SUM(o.profit) AS total_profit,
        AVG(o.lo_discount) AS avg_discount,
        SUM(o.lo_quantity) AS total_quantity
    FROM order_metrics o
    JOIN supplier s
        ON o.lo_suppkey = s.s_suppkey
    WHERE s.s_region = 'AMERICA'
    GROUP BY s.s_region, s.s_nation, s.s_city
)
SELECT
    s_region,
    s_nation,
    s_city,
    order_count,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    total_quantity,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM region_agg
ORDER BY profit_rank
LIMIT 10
