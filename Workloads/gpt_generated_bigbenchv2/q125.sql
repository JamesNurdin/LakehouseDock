WITH item_ratings AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_item_sales AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    COALESCE(si.store_quantity, 0) AS store_quantity,
    COALESCE(si.store_revenue, 0) AS store_revenue,
    COALESCE(wi.web_quantity, 0) AS web_quantity,
    COALESCE(wi.web_revenue, 0) AS web_revenue,
    COALESCE(ir.avg_rating, 0) AS avg_rating,
    COALESCE(ir.review_count, 0) AS review_count
FROM store_item_sales si
JOIN stores s
    ON si.ss_store_id = s.s_store_id
JOIN items i
    ON si.ss_item_id = i.i_item_id
LEFT JOIN web_item_sales wi
    ON i.i_item_id = wi.ws_item_id
LEFT JOIN item_ratings ir
    ON i.i_item_id = ir.pr_item_id
ORDER BY s.s_store_name, i.i_category_name, i.i_name
