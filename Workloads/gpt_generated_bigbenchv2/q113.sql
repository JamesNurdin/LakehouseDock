WITH store_agg AS (
    SELECT ss.ss_item_id AS item_id,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
sales_agg AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           i.i_price,
           COALESCE(sa.store_quantity, 0) AS store_quantity,
           COALESCE(wa.web_quantity, 0) AS web_quantity,
           COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_agg sa ON sa.item_id = i.i_item_id
    LEFT JOIN web_agg wa ON wa.item_id = i.i_item_id
),
review_agg AS (
    SELECT pr.pr_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT s.i_item_id,
       s.i_name,
       s.i_category,
       s.i_price,
       s.store_quantity,
       s.web_quantity,
       s.total_quantity,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON r.pr_item_id = s.i_item_id
WHERE s.total_quantity > 0
ORDER BY s.total_quantity DESC
LIMIT 10
