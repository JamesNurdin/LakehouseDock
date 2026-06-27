WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
item_reviews AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_item_sales AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_distinct_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY ws.ws_item_id
)
SELECT
    s.s_store_name,
    i.i_name,
    i.i_category_name,
    sis.store_quantity,
    sis.store_revenue,
    COALESCE(ir.avg_rating, 0) AS avg_item_rating,
    COALESCE(ir.review_count, 0) AS item_review_count,
    COALESCE(wis.web_quantity, 0) AS web_quantity,
    COALESCE(wis.web_distinct_customers, 0) AS web_distinct_customers,
    sis.distinct_customers AS store_distinct_customers
FROM store_item_sales sis
JOIN stores s ON sis.ss_store_id = s.s_store_id
JOIN items i ON sis.ss_item_id = i.i_item_id
LEFT JOIN item_reviews ir ON i.i_item_id = ir.i_item_id
LEFT JOIN web_item_sales wis ON i.i_item_id = wis.ws_item_id
ORDER BY s.s_store_name, i.i_name
