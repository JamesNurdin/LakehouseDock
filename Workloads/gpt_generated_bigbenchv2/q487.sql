WITH rating_per_item AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_enriched AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_price,
        r.avg_rating
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN rating_per_item r
        ON i.i_item_id = r.pr_item_id
),
store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(sse.ss_quantity * sse.i_price) AS total_revenue,
        SUM(sse.ss_quantity) AS total_quantity_sold,
        CASE WHEN SUM(sse.ss_quantity) = 0 THEN NULL
             ELSE SUM(sse.ss_quantity * COALESCE(sse.avg_rating, 0)) / SUM(sse.ss_quantity)
        END AS weighted_avg_rating
    FROM store_sales_enriched sse
    JOIN stores s
        ON sse.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT
    ssa.s_store_id,
    ssa.s_store_name,
    ssa.total_revenue,
    ssa.total_quantity_sold,
    ssa.weighted_avg_rating,
    RANK() OVER (ORDER BY ssa.total_revenue DESC) AS revenue_rank
FROM store_sales_agg ssa
ORDER BY revenue_rank
LIMIT 10
