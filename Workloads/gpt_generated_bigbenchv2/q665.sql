WITH item_sentiment AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
item_sales AS (
    SELECT
        i_item_id,
        SUM(total_qty) AS total_quantity
    FROM (
        SELECT
            ss.ss_item_id AS i_item_id,
            SUM(ss.ss_quantity) AS total_qty
        FROM store_sales ss
        GROUP BY ss.ss_item_id
        UNION ALL
        SELECT
            ws.ws_item_id AS i_item_id,
            SUM(ws.ws_quantity) AS total_qty
        FROM web_sales ws
        GROUP BY ws.ws_item_id
    ) s
    GROUP BY i_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(isales.total_quantity) AS total_quantity_sold,
    AVG(COALESCE(isent.avg_sentiment, 0)) AS avg_sentiment_score
FROM item_sales isales
JOIN items i
    ON isales.i_item_id = i.i_item_id
LEFT JOIN item_sentiment isent
    ON i.i_item_id = isent.i_item_id
GROUP BY
    i.i_category_id,
    i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
