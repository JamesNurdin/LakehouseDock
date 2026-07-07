WITH store_agg AS (
    SELECT ss_item_id,
           COUNT(ss_transaction_id) AS store_txn_count,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id,
           COUNT(ws_transaction_id) AS web_txn_count,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id,
           AVG(CAST(pr_sentiment AS double)) AS avg_review_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(COALESCE(sa.store_txn_count, 0)) AS total_store_transactions,
    SUM(COALESCE(sa.store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wa.web_txn_count, 0)) AS total_web_transactions,
    SUM(COALESCE(wa.web_quantity, 0)) AS total_web_quantity,
    AVG(ra.avg_review_sentiment) AS avg_review_sentiment,
    AVG(i.i_price) AS avg_item_price
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY i.i_category_id
