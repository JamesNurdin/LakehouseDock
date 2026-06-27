WITH
    store_sales_enriched AS (
        SELECT
            ss.ss_store_id,
            s.s_store_name,
            ss.ss_item_id,
            i.i_category_id,
            i.i_category_name,
            ss.ss_quantity,
            i.i_price,
            ss.ss_customer_id
        FROM store_sales ss
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_item_id,
            SUM(ws.ws_quantity) AS web_qty,
            SUM(ws.ws_quantity * i.i_price) AS web_rev
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_item_id
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
    ss.s_store_name,
    ss.i_category_name,
    SUM(ss.ss_quantity) AS store_qty,
    SUM(ss.ss_quantity * ss.i_price) AS store_revenue,
    COUNT(DISTINCT ss.ss_customer_id) AS unique_store_customers,
    AVG(ir.avg_rating) AS avg_item_rating,
    SUM(ir.review_cnt) AS total_item_reviews,
    COALESCE(SUM(ws.web_qty), 0) AS total_web_qty,
    COALESCE(SUM(ws.web_rev), 0) AS total_web_revenue
FROM store_sales_enriched ss
LEFT JOIN item_reviews_agg ir ON ss.ss_item_id = ir.pr_item_id
LEFT JOIN web_sales_agg ws ON ss.ss_item_id = ws.ws_item_id
GROUP BY ss.s_store_name, ss.i_category_name
ORDER BY store_revenue DESC
LIMIT 20
