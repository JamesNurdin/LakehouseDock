WITH review_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS store_qty
    FROM items i
    JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_qty
    FROM items i
    JOIN web_sales ws ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_category_id,
       i.i_category,
       AVG(r.avg_sentiment) AS category_avg_sentiment,
       SUM(COALESCE(s.store_qty, 0)) AS total_store_quantity,
       SUM(COALESCE(w.web_qty, 0)) AS total_web_quantity,
       SUM(COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0)) AS total_sales_quantity,
       SUM(COALESCE(r.review_count, 0)) AS total_review_count
FROM items i
LEFT JOIN review_agg r ON i.i_item_id = r.i_item_id
LEFT JOIN store_agg s ON i.i_item_id = s.i_item_id
LEFT JOIN web_agg w ON i.i_item_id = w.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_sales_quantity DESC
LIMIT 10
