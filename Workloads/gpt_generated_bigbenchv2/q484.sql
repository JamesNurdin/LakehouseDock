WITH store_agg AS (
       SELECT ss_item_id AS item_id,
              SUM(ss_quantity) AS store_qty,
              COUNT(DISTINCT ss_customer_id) AS store_customers
       FROM store_sales
       GROUP BY ss_item_id
     ),
     web_agg AS (
       SELECT ws_item_id AS item_id,
              SUM(ws_quantity) AS web_qty,
              COUNT(DISTINCT ws_customer_id) AS web_customers
       FROM web_sales
       GROUP BY ws_item_id
     ),
     review_agg AS (
       SELECT pr_item_id AS item_id,
              AVG(pr_sentiment) AS avg_sentiment,
              COUNT(*) AS review_count
       FROM product_reviews
       GROUP BY pr_item_id
     )
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_category_id,
       COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) AS total_quantity_sold,
       COALESCE(sa.store_customers, 0) + COALESCE(wa.web_customers, 0) AS total_distinct_customers,
       ra.avg_sentiment AS avg_review_sentiment,
       COALESCE(ra.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_quantity_sold DESC
LIMIT 10
