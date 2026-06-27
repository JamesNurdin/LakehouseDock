WITH
    store_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            s.s_store_id,
            s.s_store_name,
            SUM(ss.ss_quantity) AS total_store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY i.i_category_id, i.i_category_name, s.s_store_id, s.s_store_name
    ),
    web_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS total_web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
            COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    rating_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    )
SELECT
    s.i_category_id,
    s.i_category_name,
    s.s_store_id,
    s.s_store_name,
    s.total_store_quantity,
    s.total_store_revenue,
    w.total_web_quantity,
    w.total_web_revenue,
    r.avg_rating,
    r.review_count,
    s.distinct_store_customers,
    w.distinct_web_customers
FROM store_agg s
LEFT JOIN web_agg w
    ON s.i_category_id = w.i_category_id
   AND s.i_category_name = w.i_category_name
LEFT JOIN rating_agg r
    ON s.i_category_id = r.i_category_id
   AND s.i_category_name = r.i_category_name
ORDER BY s.total_store_quantity DESC
LIMIT 100
