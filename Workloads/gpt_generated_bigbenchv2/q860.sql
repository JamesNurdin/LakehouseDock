WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_item_sales AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    SUM(si.store_quantity) AS total_store_quantity,
    SUM(si.store_revenue) AS total_store_revenue,
    COALESCE(SUM(wi.web_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(wi.web_revenue), 0) AS total_web_revenue,
    SUM(si.store_customers) AS total_store_customers,
    COALESCE(SUM(wi.web_customers), 0) AS total_web_customers,
    AVG(ir.avg_rating) AS avg_item_rating,
    SUM(ir.review_count) AS total_review_count
FROM store_item_sales si
JOIN stores s
    ON si.ss_store_id = s.s_store_id
JOIN items i
    ON si.ss_item_id = i.i_item_id
LEFT JOIN web_item_sales wi
    ON si.ss_item_id = wi.ws_item_id
LEFT JOIN item_ratings ir
    ON i.i_item_id = ir.i_item_id
GROUP BY s.s_store_name, i.i_category_name
ORDER BY total_store_revenue DESC
LIMIT 10
