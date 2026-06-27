WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_item_sales AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_ratings AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    si.total_store_quantity,
    si.total_store_revenue,
    wi.total_web_quantity,
    wi.total_web_revenue,
    si.distinct_store_customers,
    wi.distinct_web_customers,
    ir.avg_rating,
    ir.review_count
FROM store_item_sales si
JOIN stores s
    ON si.ss_store_id = s.s_store_id
JOIN items i
    ON si.ss_item_id = i.i_item_id
LEFT JOIN web_item_sales wi
    ON si.ss_item_id = wi.ws_item_id
LEFT JOIN item_ratings ir
    ON i.i_item_id = ir.pr_item_id
ORDER BY si.total_store_quantity DESC
LIMIT 50
