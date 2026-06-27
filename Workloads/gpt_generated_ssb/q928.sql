WITH revenue_by_supplier AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_region,
        s.s_nation,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_quantity) AS total_quantity
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_region, s.s_nation
)
SELECT
    s_suppkey,
    s_name,
    s_region,
    s_nation,
    total_revenue,
    total_supplycost,
    total_quantity,
    total_revenue - total_supplycost AS profit,
    ROUND((total_revenue - total_supplycost) * 100.0 / total_revenue, 2) AS profit_margin_pct,
    ROW_NUMBER() OVER (PARTITION BY s_region ORDER BY total_revenue DESC) AS revenue_rank_in_region
FROM revenue_by_supplier
WHERE total_revenue > 0
ORDER BY s_region, revenue_rank_in_region
LIMIT 50
