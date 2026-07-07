WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_sales_amount
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_sales_amount
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    COALESCE(ssa.store_quantity, 0) AS store_quantity,
    COALESCE(ssa.store_sales_amount, 0) AS store_sales_amount,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(wa.web_sales_amount, 0) AS web_sales_amount,
    ra.avg_sentiment,
    COALESCE(ra.review_count, 0) AS review_count
FROM stores s
JOIN store_sales_agg ssa ON s.s_store_id = ssa.store_id
JOIN items i ON ssa.item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN reviews_agg ra ON i.i_item_id = ra.item_id
ORDER BY s.s_store_id, i.i_item_id
