WITH store_sales_agg AS (
    SELECT ss_item_id AS item_id,
           ss_store_id AS store_id,
           SUM(ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss_customer_id) AS distinct_store_customers
    FROM store_sales
    GROUP BY ss_item_id, ss_store_id
),
web_sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws_customer_id) AS distinct_web_customers
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
SELECT i.i_category,
       i.i_category_id,
       i.i_name,
       i.i_price,
       s.s_store_name,
       COALESCE(ssa.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(ssa.distinct_store_customers, 0) AS distinct_store_customers,
       COALESCE(wsa.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(wsa.distinct_web_customers, 0) AS distinct_web_customers,
       COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(ra.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.item_id
LEFT JOIN stores s ON ssa.store_id = s.s_store_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
WHERE i.i_price > 0
ORDER BY i.i_category_id, i.i_name, s.s_store_name
