WITH combined_sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(cs.quantity) AS total_quantity_sold,
    SUM(cs.quantity * i.i_price) AS total_revenue,
    AVG(pr.pr_sentiment) AS avg_review_sentiment
FROM combined_sales cs
JOIN items i
    ON cs.item_id = i.i_item_id
LEFT JOIN product_reviews pr
    ON pr.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_revenue DESC
