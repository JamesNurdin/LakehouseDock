WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS ss_store_id,
        ss.ss_item_id AS ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_reviews AS (
    SELECT
        pr.pr_item_id AS pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    COALESCE(ir.review_count, 0) AS review_count,
    ir.avg_rating
FROM stores s
JOIN store_sales_agg sa
    ON s.s_store_id = sa.ss_store_id
JOIN items i
    ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_sales_agg wa
    ON i.i_item_id = wa.ws_item_id
LEFT JOIN item_reviews ir
    ON i.i_item_id = ir.pr_item_id
ORDER BY total_revenue DESC
LIMIT 100
