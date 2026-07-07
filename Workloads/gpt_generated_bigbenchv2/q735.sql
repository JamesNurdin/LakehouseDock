WITH store_sales_agg AS (
    SELECT ss.ss_item_id AS item_id,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
sales_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_sales_agg s ON s.item_id = i.i_item_id
    LEFT JOIN web_sales_agg w ON w.item_id = i.i_item_id
),
reviews_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON i.i_item_id = pr.pr_item_id
    GROUP BY i.i_category
)
SELECT r.i_category,
       r.avg_sentiment,
       s.total_quantity,
       r.avg_sentiment * s.total_quantity AS weighted_sentiment
FROM reviews_agg r
JOIN sales_agg s ON s.i_category = r.i_category
ORDER BY weighted_sentiment DESC
LIMIT 10
