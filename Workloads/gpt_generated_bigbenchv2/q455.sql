WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_item_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
item_reviews AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_name,
    si.i_category_name,
    si.total_store_quantity,
    si.distinct_store_customers,
    COALESCE(wi.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(wi.distinct_web_customers, 0) AS distinct_web_customers,
    ir.avg_rating,
    ir.review_count
FROM store_item_sales si
JOIN stores s ON si.ss_store_id = s.s_store_id
LEFT JOIN web_item_sales wi ON si.i_category_id = wi.i_category_id
LEFT JOIN item_reviews ir ON si.i_category_id = ir.i_category_id
ORDER BY s.s_store_name, si.i_category_name
