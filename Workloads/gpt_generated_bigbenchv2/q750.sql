WITH combined_sales AS (
    SELECT ss.ss_item_id AS i_item_id,
           ss.ss_quantity AS quantity,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS i_item_id,
           ws.ws_quantity AS quantity,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
),
sales_agg AS (
    SELECT cs.i_item_id,
           SUM(cs.quantity) AS total_quantity,
           COUNT(DISTINCT cs.customer_id) AS distinct_customers
    FROM combined_sales cs
    GROUP BY cs.i_item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category,
       SUM(COALESCE(s.total_quantity, 0)) AS category_total_quantity,
       COUNT(DISTINCT s.i_item_id) AS distinct_items_sold,
       SUM(COALESCE(s.total_quantity, 0)) * 1.0 / NULLIF(COUNT(DISTINCT s.i_item_id), 0) AS avg_quantity_per_item,
       AVG(i.i_price) AS avg_item_price,
       AVG(r.avg_sentiment) AS avg_sentiment_per_item,
       SUM(COALESCE(r.review_count, 0)) AS total_review_count
FROM items i
LEFT JOIN sales_agg s ON s.i_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.i_item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY category_total_quantity DESC
LIMIT 10
