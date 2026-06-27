WITH store_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS total_store_qty,
           COUNT(DISTINCT ss_transaction_id) AS store_transactions
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS total_web_qty,
           COUNT(DISTINCT ws_transaction_id) AS web_transactions
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       i.i_price,
       i.i_comp_price,
       COALESCE(sa.total_store_qty, 0) AS total_store_qty,
       COALESCE(wa.total_web_qty, 0) AS total_web_qty,
       COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0) AS total_quantity_sold,
       i.i_price * (COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0)) AS total_revenue,
       ra.avg_rating,
       ra.review_count
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
ORDER BY total_quantity_sold DESC
LIMIT 100
