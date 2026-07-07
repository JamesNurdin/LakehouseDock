WITH store_sales_agg AS (
    SELECT i.i_category AS i_category,
           SUM(ss.ss_quantity) AS total_store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category AS i_category,
           SUM(ws.ws_quantity) AS total_web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT i.i_category AS i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT r.i_category,
       r.avg_sentiment,
       r.review_count,
       COALESCE(s.total_store_qty, 0) AS total_store_qty,
       COALESCE(w.total_web_qty, 0) AS total_web_qty,
       COALESCE(s.total_store_qty, 0) + COALESCE(w.total_web_qty, 0) AS total_quantity_sold
FROM reviews_agg r
LEFT JOIN store_sales_agg s ON r.i_category = s.i_category
LEFT JOIN web_sales_agg w ON r.i_category = w.i_category
ORDER BY total_quantity_sold DESC
