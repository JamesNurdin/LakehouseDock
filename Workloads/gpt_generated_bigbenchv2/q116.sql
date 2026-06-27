WITH store_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_qty,
           COUNT(DISTINCT ss_transaction_id) AS store_txn_cnt
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_qty,
           COUNT(DISTINCT ws_transaction_id) AS web_txn_cnt
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(pr_review_id) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       i.i_price,
       COALESCE(s.store_qty, 0) AS store_quantity,
       COALESCE(w.web_qty, 0) AS web_quantity,
       COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_quantity,
       COALESCE(s.store_txn_cnt, 0) AS store_transactions,
       COALESCE(w.web_txn_cnt, 0) AS web_transactions,
       COALESCE(r.avg_rating, 0) AS average_rating,
       COALESCE(r.review_cnt, 0) AS review_count,
       i.i_price * (COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0)) AS revenue
FROM items i
LEFT JOIN store_agg s ON s.ss_item_id = i.i_item_id
LEFT JOIN web_agg w ON w.ws_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 100
