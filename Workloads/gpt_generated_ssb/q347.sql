WITH revenue_by_brand AS (
    SELECT
        p.p_category,
        p.p_brand1,
        SUM(l.lo_revenue) AS total_revenue,
        COUNT(*) AS order_cnt
    FROM lineorder l
    JOIN part p ON l.lo_partkey = p.p_partkey
    WHERE l.lo_quantity BETWEEN 1 AND 50
    GROUP BY p.p_category, p.p_brand1
),
total_by_category AS (
    SELECT
        p_category,
        SUM(total_revenue) AS category_revenue
    FROM revenue_by_brand
    GROUP BY p_category
)
SELECT
    r.p_category,
    r.p_brand1,
    r.total_revenue,
    r.order_cnt,
    r.total_revenue * 100.0 / t.category_revenue AS revenue_pct,
    RANK() OVER (PARTITION BY r.p_category ORDER BY r.total_revenue DESC) AS brand_rank
FROM revenue_by_brand r
JOIN total_by_category t
    ON r.p_category = t.p_category
ORDER BY r.p_category, revenue_pct DESC
LIMIT 20
