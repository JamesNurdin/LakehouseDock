WITH store_item_sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_item_id, i.i_category_id, i.i_category_name, i.i_price
),
item_reviews AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_cnt
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
item_web_sales AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    GROUP BY ws.ws_item_id
)
SELECT
    s.s_store_name,
    si.i_category_name,
    SUM(si.store_qty) AS total_store_quantity,
    COALESCE(SUM(w.web_qty), 0) AS total_web_quantity,
    ROUND(AVG(ir.avg_rating), 2) AS avg_item_rating,
    ROUND(AVG(si.i_price), 2) AS avg_item_price,
    COUNT(DISTINCT si.i_item_id) AS distinct_items_sold
FROM store_item_sales si
JOIN stores s ON si.store_id = s.s_store_id
LEFT JOIN item_reviews ir ON si.i_item_id = ir.pr_item_id
LEFT JOIN item_web_sales w ON si.i_item_id = w.ws_item_id
GROUP BY s.s_store_name, si.i_category_name
ORDER BY s.s_store_name, total_store_quantity DESC
