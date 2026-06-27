WITH brand_category_sales AS (
    SELECT
        p.p_category,
        p.p_brand1,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_shipmode = 'AIR'   -- example filter on a non‑date column
    GROUP BY p.p_category, p.p_brand1
)
SELECT
    p_category,
    p_brand1,
    total_revenue,
    total_quantity,
    avg_discount,
    total_revenue / SUM(total_revenue) OVER (PARTITION BY p_category) * 100 AS revenue_pct,
    RANK() OVER (PARTITION BY p_category ORDER BY total_revenue DESC) AS revenue_rank_within_category
FROM brand_category_sales
ORDER BY p_category, revenue_rank_within_category
