WITH store_agg AS (
    SELECT ss.ss_item_id AS i_item_id,
           SUM(ss.ss_quantity) AS total_store_qty,
           SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT ws.ws_item_id AS i_item_id,
           SUM(ws.ws_quantity) AS total_web_qty,
           SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(s.total_store_qty, 0) AS total_store_qty,
       COALESCE(s.total_store_revenue, 0) AS total_store_revenue,
       COALESCE(w.total_web_qty, 0) AS total_web_qty,
       COALESCE(w.total_web_revenue, 0) AS total_web_revenue,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count,
       (COALESCE(s.total_store_qty, 0) + COALESCE(w.total_web_qty, 0)) AS total_quantity
FROM items i
LEFT JOIN store_agg s ON i.i_item_id = s.i_item_id
LEFT JOIN web_agg w ON i.i_item_id = w.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.i_item_id
ORDER BY total_quantity DESC
LIMIT 100
