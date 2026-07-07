WITH store_agg AS (
    SELECT ss_item_id AS item_id,
           COUNT(DISTINCT ss_transaction_id) AS store_txn_cnt,
           SUM(ss_quantity) AS total_store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS item_id,
           COUNT(DISTINCT ws_transaction_id) AS web_txn_cnt,
           SUM(ws_quantity) AS total_web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           COUNT(*) AS review_cnt,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_name,
       COALESCE(sa.store_txn_cnt, 0) AS store_txn_cnt,
       COALESCE(sa.total_store_qty, 0) AS total_store_qty,
       COALESCE(wa.web_txn_cnt, 0) AS web_txn_cnt,
       COALESCE(wa.total_web_qty, 0) AS total_web_qty,
       COALESCE(ra.review_cnt, 0) AS review_cnt,
       ra.avg_sentiment
FROM items i
LEFT JOIN store_agg sa ON sa.item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.item_id = i.i_item_id
WHERE i.i_category IS NOT NULL
ORDER BY i.i_category, i.i_name
