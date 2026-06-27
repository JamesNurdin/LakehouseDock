WITH sales AS (
    -- Store sales rows with item category information
    SELECT
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS store_quantity,
        ss.ss_quantity * i.i_price AS store_revenue,
        ss.ss_customer_id AS store_customer_id,
        0 AS web_quantity,
        0.0 AS web_revenue,
        NULL AS web_customer_id,
        NULL AS rating,
        NULL AS review_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    
    UNION ALL
    
    -- Web sales rows with item category information
    SELECT
        i.i_category_id,
        i.i_category_name,
        0 AS store_quantity,
        0.0 AS store_revenue,
        NULL AS store_customer_id,
        ws.ws_quantity AS web_quantity,
        ws.ws_quantity * i.i_price AS web_revenue,
        ws.ws_customer_id AS web_customer_id,
        NULL AS rating,
        NULL AS review_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    
    UNION ALL
    
    -- Product review rows with item category information
    SELECT
        i.i_category_id,
        i.i_category_name,
        0 AS store_quantity,
        0.0 AS store_revenue,
        NULL AS store_customer_id,
        0 AS web_quantity,
        0.0 AS web_revenue,
        NULL AS web_customer_id,
        pr.pr_rating AS rating,
        pr.pr_review_id AS review_id
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
)
SELECT
    i_category_id AS category_id,
    i_category_name AS category_name,
    SUM(store_quantity) AS total_store_quantity,
    SUM(web_quantity) AS total_web_quantity,
    SUM(store_revenue) AS total_store_revenue,
    SUM(web_revenue) AS total_web_revenue,
    COUNT(DISTINCT store_customer_id) + COUNT(DISTINCT web_customer_id) AS total_distinct_customers,
    AVG(rating) AS avg_rating,
    COUNT(review_id) AS review_count
FROM sales
GROUP BY i_category_id, i_category_name
ORDER BY (total_store_revenue + total_web_revenue) DESC
LIMIT 10
