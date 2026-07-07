WITH sentiment_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
sales_by_category AS (
    SELECT
        combined_sales.i_category_id,
        combined_sales.i_category,
        SUM(combined_sales.sales_qty) AS total_quantity
    FROM (
        SELECT
            i.i_category_id,
            i.i_category,
            ss.ss_quantity AS sales_qty
        FROM store_sales ss
        JOIN items i
            ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT
            i.i_category_id,
            i.i_category,
            ws.ws_quantity AS sales_qty
        FROM web_sales ws
        JOIN items i
            ON ws.ws_item_id = i.i_item_id
    ) AS combined_sales
    GROUP BY combined_sales.i_category_id, combined_sales.i_category
)
SELECT
    sbc.i_category_id,
    sbc.i_category,
    sbc.avg_sentiment,
    s.total_quantity
FROM sentiment_by_category sbc
JOIN sales_by_category s
    ON sbc.i_category_id = s.i_category_id
    AND sbc.i_category = s.i_category
ORDER BY sbc.avg_sentiment DESC
LIMIT 5
