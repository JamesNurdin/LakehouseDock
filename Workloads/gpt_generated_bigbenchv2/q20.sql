WITH item_review_stats AS (
    SELECT i.i_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sales_data AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_store_id AS store_id,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           NULL AS store_id,
           'web' AS channel
    FROM web_sales ws
)
SELECT i.i_category,
       SUM(s.quantity) AS total_quantity,
       AVG(i.i_price) AS avg_price,
       AVG(r.avg_sentiment) AS avg_sentiment,
       SUM(r.review_count) AS total_reviews
FROM sales_data s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN item_review_stats r ON i.i_item_id = r.item_id
LEFT JOIN stores st ON s.store_id = st.s_store_id
GROUP BY i.i_category
ORDER BY total_quantity DESC
