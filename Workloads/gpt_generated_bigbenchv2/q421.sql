WITH unified_sales AS (
    SELECT ss.ss_item_id AS i_item_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS i_item_id,
           ws.ws_quantity AS quantity
    FROM web_sales ws
),

total_sales AS (
    SELECT i_item_id,
           SUM(quantity) AS total_quantity
    FROM unified_sales
    GROUP BY i_item_id
),

review_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           i.i_category,
           i.i_category_id
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category, i.i_category_id
)
SELECT r.i_category,
       r.i_category_id,
       SUM(r.avg_sentiment * ts.total_quantity) / NULLIF(SUM(ts.total_quantity), 0) AS weighted_avg_sentiment,
       SUM(ts.total_quantity) AS total_quantity_sold
FROM review_agg r
JOIN total_sales ts ON r.i_item_id = ts.i_item_id
GROUP BY r.i_category, r.i_category_id
ORDER BY weighted_avg_sentiment DESC
LIMIT 5
