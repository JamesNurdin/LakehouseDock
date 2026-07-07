WITH sales_agg AS (
    SELECT i_category, SUM(qty) AS total_quantity
    FROM (
        SELECT i.i_category AS i_category, ss.ss_quantity AS qty
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT i.i_category AS i_category, ws.ws_quantity AS qty
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ) s
    GROUP BY i_category
),
price_agg AS (
    SELECT i_category, AVG(i_price) AS avg_price
    FROM items
    GROUP BY i_category
),
review_agg AS (
    SELECT i.i_category AS i_category,
           COUNT(pr.pr_review_id) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    sa.i_category AS category,
    sa.total_quantity,
    pa.avg_price,
    ra.review_count,
    ra.avg_sentiment
FROM sales_agg sa
LEFT JOIN price_agg pa ON sa.i_category = pa.i_category
LEFT JOIN review_agg ra ON sa.i_category = ra.i_category
ORDER BY sa.total_quantity DESC
LIMIT 10
