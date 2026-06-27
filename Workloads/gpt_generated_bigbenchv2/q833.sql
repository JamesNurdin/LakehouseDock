WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS ss_store_id,
        ss.ss_item_id AS ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_ratings AS (
    SELECT
        pr.pr_item_id AS pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    SUM(sa.store_quantity) AS total_store_quantity,
    SUM(sa.store_revenue) AS total_store_revenue,
    COALESCE(SUM(wa.web_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(wa.web_revenue), 0) AS total_web_revenue,
    AVG(ir.avg_rating) AS avg_item_rating,
    COUNT(DISTINCT sa.ss_item_id) AS distinct_items_sold
FROM store_sales_agg sa
JOIN stores s ON sa.ss_store_id = s.s_store_id
JOIN items i ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON sa.ss_item_id = wa.ws_item_id
LEFT JOIN item_ratings ir ON sa.ss_item_id = ir.pr_item_id
GROUP BY s.s_store_name, i.i_category_name
HAVING COUNT(DISTINCT sa.ss_item_id) >= 5
ORDER BY total_store_revenue DESC
LIMIT 100
