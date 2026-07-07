WITH store_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss_customer_id) AS distinct_store_customers
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws_customer_id) AS distinct_web_customers
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id AS i_item_id,
           SUM(pr_sentiment) AS sum_sentiment,
           COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0)) AS total_quantity_sold,
       SUM(COALESCE(sa.distinct_store_customers, 0) + COALESCE(wa.distinct_web_customers, 0)) AS total_distinct_customers,
       AVG(i.i_price) AS avg_item_price,
       SUM(ra.sum_sentiment) / NULLIF(SUM(ra.review_count), 0) AS avg_sentiment,
       SUM(ra.review_count) AS total_reviews
FROM items i
LEFT JOIN store_agg sa ON sa.i_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.i_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.i_item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
