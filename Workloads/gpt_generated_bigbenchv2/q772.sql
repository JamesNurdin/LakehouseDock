WITH sales_and_reviews AS (
    SELECT i.i_category_id,
           i.i_category,
           ss.ss_quantity AS sales_quantity,
           'store' AS sales_channel,
           CAST(NULL AS integer) AS review_sentiment
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT i.i_category_id,
           i.i_category,
           ws.ws_quantity AS sales_quantity,
           'web' AS sales_channel,
           CAST(NULL AS integer) AS review_sentiment
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id

    UNION ALL

    SELECT i.i_category_id,
           i.i_category,
           0 AS sales_quantity,
           CAST(NULL AS varchar) AS sales_channel,
           pr.pr_sentiment AS review_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
)
SELECT
    i_category_id,
    i_category,
    SUM(sales_quantity) AS total_quantity,
    SUM(CASE WHEN sales_channel = 'store' THEN sales_quantity ELSE 0 END) AS store_quantity,
    SUM(CASE WHEN sales_channel = 'web' THEN sales_quantity ELSE 0 END) AS web_quantity,
    AVG(review_sentiment) AS avg_sentiment,
    COUNT(review_sentiment) AS review_count
FROM sales_and_reviews
GROUP BY i_category_id, i_category
ORDER BY i_category_id
