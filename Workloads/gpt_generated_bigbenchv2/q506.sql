WITH combined_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category,
        i.i_price,
        COALESCE(SUM(cs.quantity), 0) AS total_quantity,
        COALESCE(SUM(cs.quantity) * i.i_price, 0) AS total_revenue
    FROM items i
    LEFT JOIN combined_sales cs ON cs.item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category, i.i_price
),
review_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.i_item_id,
    s.i_name,
    s.i_category,
    s.i_price,
    s.total_quantity,
    s.total_revenue,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON r.i_item_id = s.i_item_id
ORDER BY s.total_revenue DESC
LIMIT 10
