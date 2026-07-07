WITH review_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
store_sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT r.i_category,
       r.avg_sentiment,
       r.review_count,
       COALESCE(s.store_quantity, 0) AS store_quantity,
       COALESCE(w.web_quantity, 0) AS web_quantity,
       COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
FROM review_agg r
LEFT JOIN store_sales_agg s ON r.i_category = s.i_category
LEFT JOIN web_sales_agg w ON r.i_category = w.i_category
ORDER BY r.avg_sentiment DESC
