WITH
    store_sales_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS total_store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
            COUNT(DISTINCT s.s_store_id) AS distinct_store_count,
            COUNT(DISTINCT c.c_customer_id) AS distinct_store_customer_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS total_web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
            COUNT(DISTINCT c.c_customer_id) AS distinct_web_customer_count
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        JOIN customers c ON ws.ws_customer_id = c.c_customer_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    reviews_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    customers_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            COUNT(DISTINCT c.c_customer_id) AS total_distinct_customers
        FROM (
            SELECT ss.ss_customer_id AS customer_id, ss.ss_item_id AS item_id
            FROM store_sales ss
            UNION ALL
            SELECT ws.ws_customer_id AS customer_id, ws.ws_item_id AS item_id
            FROM web_sales ws
        ) AS sales
        JOIN items i ON sales.item_id = i.i_item_id
        JOIN customers c ON sales.customer_id = c.c_customer_id
        GROUP BY i.i_category_id, i.i_category_name
    )
SELECT
    COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id, ca.i_category_id) AS category_id,
    COALESCE(ss.i_category_name, ws.i_category_name, r.i_category_name, ca.i_category_name) AS category_name,
    ss.total_store_quantity,
    ws.total_web_quantity,
    ss.total_store_revenue,
    ws.total_web_revenue,
    r.avg_rating,
    r.review_count,
    ca.total_distinct_customers,
    ss.distinct_store_customer_count,
    ws.distinct_web_customer_count,
    ss.distinct_store_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(ss.i_category_id, ws.i_category_id) = r.i_category_id
FULL OUTER JOIN customers_agg ca
    ON COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id) = ca.i_category_id
ORDER BY COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0) DESC
