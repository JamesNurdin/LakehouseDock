WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        COUNT(ss.ss_transaction_id) AS transaction_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price
),
review_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
combined AS (
    SELECT
        sagg.i_category_id,
        sagg.i_category_name,
        sagg.i_item_id,
        sagg.i_name,
        sagg.total_quantity,
        sagg.total_revenue,
        sagg.distinct_customers,
        sagg.transaction_count,
        COALESCE(ragg.avg_rating, 0) AS avg_rating,
        COALESCE(ragg.review_count, 0) AS review_count
    FROM sales_agg sagg
    LEFT JOIN review_agg ragg ON sagg.i_item_id = ragg.pr_item_id
),
ranked AS (
    SELECT
        combined.*,
        row_number() OVER (PARTITION BY combined.i_category_id ORDER BY combined.total_revenue DESC) AS revenue_rank
    FROM combined
)
SELECT
    ranked.i_category_id,
    ranked.i_category_name,
    ranked.i_item_id,
    ranked.i_name,
    ranked.total_quantity,
    ranked.total_revenue,
    ranked.distinct_customers,
    ranked.transaction_count,
    ranked.avg_rating,
    ranked.review_count,
    ranked.revenue_rank
FROM ranked
WHERE ranked.revenue_rank <= 3
ORDER BY ranked.i_category_id, ranked.revenue_rank
