WITH store_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(ssa.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(wsa.total_web_quantity, 0) AS total_web_quantity,
       r.avg_sentiment,
       r.review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
WHERE i.i_category IS NOT NULL
ORDER BY i.i_category, i.i_name
LIMIT 100
