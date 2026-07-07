WITH item_sales AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category,
           i.i_price,
           SUM(ss.ss_quantity) AS store_qty,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category, i.i_price
),
web_item_sales AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_qty,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
item_reviews AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0)) AS total_quantity,
       SUM(COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0)) AS total_revenue,
       AVG(r.avg_sentiment) AS avg_sentiment
FROM items i
LEFT JOIN item_sales s ON i.i_item_id = s.i_item_id
LEFT JOIN web_item_sales w ON i.i_item_id = w.i_item_id
LEFT JOIN item_reviews r ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
