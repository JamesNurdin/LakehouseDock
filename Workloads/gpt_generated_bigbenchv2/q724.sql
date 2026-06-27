WITH
    store_sales_agg AS (
        SELECT
            s.s_store_id,
            s.s_store_name,
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS store_total_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_total_revenue,
            COUNT(DISTINCT c.c_customer_id) AS store_customer_count
        FROM store_sales ss
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY
            s.s_store_id,
            s.s_store_name,
            i.i_category_id,
            i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS web_total_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_total_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY
            i.i_category_id,
            i.i_category_name
    ),
    reviews_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY
            i.i_category_id,
            i.i_category_name
    )
SELECT
    ss.s_store_id,
    ss.s_store_name,
    ss.i_category_id,
    ss.i_category_name,
    ss.store_total_quantity,
    ss.store_total_revenue,
    ss.store_customer_count,
    COALESCE(ws.web_total_quantity, 0) AS web_total_quantity,
    COALESCE(ws.web_total_revenue, 0) AS web_total_revenue,
    COALESCE(rv.avg_rating, 0) AS avg_rating,
    COALESCE(rv.review_count, 0) AS review_count
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
   AND ss.i_category_name = ws.i_category_name
LEFT JOIN reviews_agg rv
    ON ss.i_category_id = rv.i_category_id
   AND ss.i_category_name = rv.i_category_name
ORDER BY ss.store_total_revenue DESC
LIMIT 100
