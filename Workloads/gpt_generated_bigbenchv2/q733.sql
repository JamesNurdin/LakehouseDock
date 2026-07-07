WITH combined_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT
        cs.item_id,
        SUM(cs.quantity) AS total_quantity,
        SUM(cs.quantity * i.i_price) AS total_revenue
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY cs.item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_category_id,
    sa.total_quantity,
    sa.total_revenue,
    COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(ra.review_count, 0) AS review_count
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN reviews_agg ra ON i.i_item_id = ra.item_id
ORDER BY sa.total_revenue DESC
LIMIT 10
