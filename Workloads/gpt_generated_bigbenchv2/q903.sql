WITH store_item_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category
),
item_review_sentiment AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    sis.s_store_name,
    sis.i_category,
    sis.total_quantity,
    sis.total_revenue,
    irs.avg_sentiment,
    irs.review_count
FROM store_item_sales sis
LEFT JOIN item_review_sentiment irs
    ON sis.i_category_id = irs.i_category_id
ORDER BY sis.s_store_name, sis.i_category
