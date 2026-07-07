WITH store_agg AS (
    SELECT ss.ss_item_id,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT ws.ws_item_id,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT pr.pr_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(s.store_qty, 0)) AS total_store_quantity,
       SUM(COALESCE(w.web_qty, 0)) AS total_web_quantity,
       AVG(r.avg_sentiment) AS avg_review_sentiment,
       AVG(i.i_price) AS avg_item_price
FROM items i
LEFT JOIN store_agg s ON s.ss_item_id = i.i_item_id
LEFT JOIN web_agg w ON w.ws_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_store_quantity DESC
LIMIT 10
