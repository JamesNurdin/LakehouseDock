WITH item_reviews AS (
    SELECT i.i_item_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
store_sales_agg AS (
    SELECT ss.ss_item_id,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
item_customers AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION
    SELECT ws.ws_item_id AS item_id,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
)
SELECT i_reviews.i_category,
       COUNT(DISTINCT i_reviews.i_item_id) AS num_items,
       AVG(i_reviews.avg_sentiment) AS avg_sentiment_per_category,
       COALESCE(SUM(s.store_qty), 0) AS total_store_quantity,
       COALESCE(SUM(w.web_qty), 0) AS total_web_quantity,
       COUNT(DISTINCT ic.customer_id) AS total_distinct_customers
FROM item_reviews i_reviews
LEFT JOIN store_sales_agg s ON i_reviews.i_item_id = s.ss_item_id
LEFT JOIN web_sales_agg w ON i_reviews.i_item_id = w.ws_item_id
LEFT JOIN item_customers ic ON i_reviews.i_item_id = ic.item_id
GROUP BY i_reviews.i_category
ORDER BY total_store_quantity DESC
LIMIT 10
