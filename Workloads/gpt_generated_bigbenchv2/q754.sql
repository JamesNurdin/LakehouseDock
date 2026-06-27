WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_id,
            i.i_category_id,
            i.i_category_name,
            ss.ss_item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY
            ss.ss_store_id,
            i.i_category_id,
            i.i_category_name,
            ss.ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            ws.ws_item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY
            i.i_category_id,
            i.i_category_name,
            ws.ws_item_id
    ),
    item_reviews_agg AS (
        SELECT
            pr.pr_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_cnt
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
    COALESCE(ir.avg_rating, 0) AS avg_rating,
    i.i_price
FROM store_sales_agg sa
FULL OUTER JOIN web_sales_agg wa
    ON sa.ss_item_id = wa.ws_item_id
    AND sa.i_category_id = wa.i_category_id
LEFT JOIN items i
    ON COALESCE(sa.ss_item_id, wa.ws_item_id) = i.i_item_id
LEFT JOIN stores s
    ON sa.ss_store_id = s.s_store_id
LEFT JOIN item_reviews_agg ir
    ON i.i_item_id = ir.pr_item_id
ORDER BY total_quantity DESC
LIMIT 10
