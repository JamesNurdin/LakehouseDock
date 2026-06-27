WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_id,
            ss.ss_item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS distinct_customer_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_store_id, ss.ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_item_id
    ),
    reviews_agg AS (
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
    ssagg.store_quantity,
    ssagg.store_revenue,
    ssagg.distinct_customer_count,
    wa.web_quantity,
    wa.web_revenue,
    ra.avg_rating,
    ra.review_count
FROM store_sales_agg ssagg
JOIN stores s ON ssagg.ss_store_id = s.s_store_id
JOIN items i ON ssagg.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON ssagg.ss_item_id = wa.ws_item_id
LEFT JOIN reviews_agg ra ON ssagg.ss_item_id = ra.pr_item_id
ORDER BY s.s_store_name, i.i_category_name, i.i_name
