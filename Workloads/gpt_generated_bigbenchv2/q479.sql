WITH store_qty AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_qty AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           COALESCE(sq.store_quantity, 0) + COALESCE(wq.web_quantity, 0) AS total_quantity,
           i.i_price
    FROM items i
    LEFT JOIN store_qty sq ON i.i_item_id = sq.item_id
    LEFT JOIN web_qty wq ON i.i_item_id = wq.item_id
),
item_reviews AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i_sales.i_item_id,
       i_sales.i_name,
       i_sales.i_category,
       i_sales.total_quantity,
       i_sales.i_price,
       COALESCE(i_rev.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(i_rev.review_count, 0) AS review_count
FROM item_sales i_sales
LEFT JOIN item_reviews i_rev ON i_sales.i_item_id = i_rev.item_id
ORDER BY i_sales.total_quantity DESC
LIMIT 10
