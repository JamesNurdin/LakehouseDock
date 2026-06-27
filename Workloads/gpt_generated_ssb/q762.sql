WITH aggregated AS (
    SELECT
        s.s_region,
        p.p_category,
        s.s_name,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS line_count
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    GROUP BY s.s_region, p.p_category, s.s_name
),
ranked AS (
    SELECT
        s_region,
        p_category,
        s_name,
        total_revenue,
        total_supply_cost,
        total_profit,
        avg_discount,
        line_count,
        ROW_NUMBER() OVER (PARTITION BY p_category ORDER BY total_profit DESC) AS profit_rank_in_category
    FROM aggregated
)
SELECT
    s_region,
    p_category,
    s_name,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    line_count,
    profit_rank_in_category
FROM ranked
WHERE profit_rank_in_category <= 5
ORDER BY p_category, profit_rank_in_category
