WITH category_supplier AS (
    SELECT
        p.p_category,
        s.s_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    GROUP BY p.p_category, s.s_region
)
SELECT
    p_category,
    s_region,
    total_revenue,
    total_supplycost,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY p_category ORDER BY total_profit DESC) AS profit_rank
FROM category_supplier
ORDER BY p_category, profit_rank
LIMIT 50
