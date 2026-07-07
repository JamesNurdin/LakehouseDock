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
item_reviews AS (
    SELECT i.i_item_id AS item_id,
           AVG(CAST(pr_sentiment AS double)) AS avg_sentiment,
           COUNT(pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_item_id AS item_id,
       i.i_name AS item_name,
       i.i_category AS category,
       i.i_price AS price,
       COALESCE(sq.store_quantity, 0) AS store_quantity,
       COALESCE(wq.web_quantity, 0) AS web_quantity,
       COALESCE(sq.store_quantity, 0) + COALESCE(wq.web_quantity, 0) AS total_quantity,
       ir.avg_sentiment,
       ir.review_count
FROM items i
LEFT JOIN store_qty sq ON sq.item_id = i.i_item_id
LEFT JOIN web_qty wq ON wq.item_id = i.i_item_id
LEFT JOIN item_reviews ir ON ir.item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 10
