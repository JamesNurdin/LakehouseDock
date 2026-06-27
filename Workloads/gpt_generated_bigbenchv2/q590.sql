WITH store_sales_by_store_cat AS (
    SELECT s.s_store_id,
           s.s_store_name,
           i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(ss.ss_transaction_id) AS store_txn_cnt
    FROM store_sales ss
    JOIN stores s ON s.s_store_id = ss.ss_store_id
    JOIN items i ON i.i_item_id = ss.ss_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_sales_by_cat AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity) AS total_web_quantity,
           COUNT(ws.ws_transaction_id) AS web_txn_cnt
    FROM web_sales ws
    JOIN items i ON i.i_item_id = ws.ws_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_stats_by_cat AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON i.i_item_id = pr.pr_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
price_stats_by_cat AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(i.i_price) AS avg_price,
           COUNT(i.i_item_id) AS item_cnt
    FROM items i
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT ss.s_store_name,
       ss.i_category_name,
       ss.total_store_quantity,
       COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(r.avg_rating, 0) AS avg_item_rating,
       COALESCE(p.avg_price, 0) AS avg_item_price,
       ss.total_store_quantity + COALESCE(ws.total_web_quantity, 0) AS total_quantity_all_channels,
       COALESCE(r.review_cnt, 0) AS total_review_count,
       COALESCE(p.item_cnt, 0) AS distinct_items_in_category
FROM store_sales_by_store_cat ss
LEFT JOIN web_sales_by_cat ws ON ws.i_category_id = ss.i_category_id
LEFT JOIN review_stats_by_cat r ON r.i_category_id = ss.i_category_id
LEFT JOIN price_stats_by_cat p ON p.i_category_id = ss.i_category_id
WHERE ss.total_store_quantity > 0
ORDER BY total_quantity_all_channels DESC
LIMIT 50
