WITH store_item_agg AS (
    SELECT
        ss_store_id,
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss_customer_id) AS store_customers
    FROM store_sales
    GROUP BY ss_store_id, ss_item_id
),
web_item_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws_customer_id) AS web_customers
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(si.store_quantity) AS total_store_quantity,
    SUM(COALESCE(wi.web_quantity, 0)) AS total_web_quantity,
    SUM(si.store_quantity * i.i_price) AS total_store_revenue,
    SUM(COALESCE(wi.web_quantity, 0) * i.i_price) AS total_web_revenue,
    SUM(si.store_quantity * ra.avg_rating) / NULLIF(SUM(si.store_quantity), 0) AS weighted_avg_rating,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
    SUM(si.store_quantity + COALESCE(wi.web_quantity, 0)) AS total_quantity,
    (SUM(si.store_quantity * i.i_price) + SUM(COALESCE(wi.web_quantity, 0) * i.i_price)) AS total_revenue
FROM store_item_agg si
JOIN items i ON si.ss_item_id = i.i_item_id
JOIN stores s ON si.ss_store_id = s.s_store_id
LEFT JOIN web_item_agg wi ON wi.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_store_revenue DESC
LIMIT 5
