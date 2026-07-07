WITH avg_sentiment AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sales_combined AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_store_id AS store_id,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           NULL AS store_id,
           'web' AS channel
    FROM web_sales ws
)
SELECT i.i_category_id,
       i.i_category,
       SUM(sc.quantity) AS total_quantity_sold,
       COUNT(DISTINCT sc.customer_id) AS distinct_customers,
       AVG(i.i_price) AS avg_item_price,
       SUM(COALESCE(avg_sent.avg_sentiment, 0) * sc.quantity) / NULLIF(SUM(sc.quantity), 0) AS weighted_avg_review_sentiment,
       COUNT(DISTINCT sc.store_id) AS distinct_stores_sold
FROM sales_combined sc
JOIN items i ON sc.item_id = i.i_item_id
JOIN customers c ON sc.customer_id = c.c_customer_id
LEFT JOIN avg_sentiment avg_sent ON i.i_item_id = avg_sent.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
