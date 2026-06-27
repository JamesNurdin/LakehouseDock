WITH
    store_sales_agg AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(i.i_price * ss.ss_quantity) AS store_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        JOIN customers c ON ws.ws_customer_id = c.c_customer_id
        GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name
    ),
    rating_agg AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name
    )
SELECT
    COALESCE(s.i_item_id, w.i_item_id, r.i_item_id) AS item_id,
    COALESCE(s.i_name, w.i_name, r.i_name) AS item_name,
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS category_id,
    COALESCE(s.i_category_name, w.i_category_name, r.i_category_name) AS category_name,
    COALESCE(s.store_quantity, 0) AS total_store_quantity,
    COALESCE(s.store_revenue, 0) AS total_store_revenue,
    COALESCE(w.web_quantity, 0) AS total_web_quantity,
    COALESCE(s.store_customer_count, 0) + COALESCE(w.web_customer_count, 0) AS total_customer_count,
    COALESCE(r.avg_rating, 0) AS average_rating,
    COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w
    ON s.i_item_id = w.i_item_id
FULL OUTER JOIN rating_agg r
    ON COALESCE(s.i_item_id, w.i_item_id) = r.i_item_id
ORDER BY total_store_revenue DESC, total_web_quantity DESC
LIMIT 100
