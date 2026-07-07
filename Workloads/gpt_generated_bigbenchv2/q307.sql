WITH store_item_sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
item_reviews AS (
    SELECT
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_item_sales AS (
    SELECT
        i.i_category AS category,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    sis.category,
    sis.total_store_quantity,
    wis.total_web_quantity,
    ir.avg_sentiment,
    ir.review_count,
    sis.distinct_customers
FROM store_item_sales sis
JOIN stores s ON sis.store_id = s.s_store_id
LEFT JOIN item_reviews ir ON sis.category = ir.category
LEFT JOIN web_item_sales wis ON sis.category = wis.category
ORDER BY s.s_store_name, sis.category
