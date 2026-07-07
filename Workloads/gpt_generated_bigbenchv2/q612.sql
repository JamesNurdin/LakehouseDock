WITH sales_by_channel AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        s.s_store_name AS sales_channel,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category, s.s_store_name
    UNION ALL
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        'Online' AS sales_channel,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    sbc.category_id,
    sbc.category_name,
    sbc.sales_channel,
    sbc.total_quantity,
    ra.avg_sentiment,
    ra.review_count
FROM sales_by_channel sbc
LEFT JOIN review_agg ra ON sbc.category_id = ra.category_id
ORDER BY sbc.category_name, sbc.sales_channel
