WITH store_aggregates AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss_customer_id) AS store_customer_count
    FROM store_sales
    GROUP BY ss_item_id
),
web_aggregates AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws_customer_id) AS web_customer_count
    FROM web_sales
    GROUP BY ws_item_id
),
review_aggregates AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(sa.store_quantity, 0) AS total_store_quantity,
       COALESCE(wa.web_quantity, 0) AS total_web_quantity,
       COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
       COALESCE(sa.store_customer_count, 0) AS store_customer_count,
       COALESCE(wa.web_customer_count, 0) AS web_customer_count,
       COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(ra.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_aggregates sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_aggregates wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_aggregates ra ON i.i_item_id = ra.pr_item_id
ORDER BY total_quantity DESC
LIMIT 10
