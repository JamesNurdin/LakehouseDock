WITH store_sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss_transaction_id) AS store_transaction_count
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws_transaction_id) AS web_transaction_count
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_id,
       i.i_category_name,
       i.i_price,
       i.i_comp_price,
       i.i_class_id,
       COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0) AS total_quantity,
       COALESCE(s.store_transaction_count, 0) + COALESCE(w.web_transaction_count, 0) AS total_transactions,
       COALESCE(r.avg_rating, 0) AS avg_rating,
       COALESCE(r.review_count, 0) AS review_count,
       (COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0)) * i.i_price AS estimated_revenue
FROM items i
LEFT JOIN store_sales_agg s ON s.item_id = i.i_item_id
LEFT JOIN web_sales_agg w ON w.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
WHERE i.i_price > 0
ORDER BY avg_rating DESC, estimated_revenue DESC
LIMIT 100
