WITH store_item_agg AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_item_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
review_item_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_name AS item_name,
    i.i_category_name,
    si.store_quantity,
    si.store_revenue,
    COALESCE(wi.web_quantity, 0) AS web_quantity,
    COALESCE(wi.web_revenue, 0) AS web_revenue,
    COALESCE(ri.avg_rating, 0) AS avg_rating,
    COALESCE(ri.review_count, 0) AS review_count,
    si.store_customer_count
FROM store_item_agg si
JOIN stores s ON si.ss_store_id = s.s_store_id
JOIN items i ON si.ss_item_id = i.i_item_id
LEFT JOIN web_item_agg wi ON si.ss_item_id = wi.ws_item_id
LEFT JOIN review_item_agg ri ON si.ss_item_id = ri.pr_item_id
ORDER BY s.s_store_name, i.i_name
