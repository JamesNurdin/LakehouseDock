WITH combined_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM combined_sales
    GROUP BY item_id
),
review_agg AS (
    SELECT pr_item_id, AVG(pr_sentiment) AS avg_sentiment, COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    SUM(s.total_quantity) AS total_quantity_sold,
    SUM(s.total_quantity * i.i_price) AS total_revenue,
    AVG(r.avg_sentiment) AS avg_review_sentiment,
    SUM(r.review_count) AS total_reviews
FROM sales_agg s
JOIN items i
    ON s.item_id = i.i_item_id
LEFT JOIN review_agg r
    ON i.i_item_id = r.pr_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
