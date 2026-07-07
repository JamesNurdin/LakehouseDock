WITH sales_agg AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category
),
web_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
       r.avg_sentiment,
       r.review_count
FROM items i
LEFT JOIN sales_agg s ON i.i_item_id = s.i_item_id
LEFT JOIN web_sales_agg w ON i.i_item_id = w.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
WHERE r.review_count >= 5
ORDER BY total_quantity DESC
LIMIT 10
