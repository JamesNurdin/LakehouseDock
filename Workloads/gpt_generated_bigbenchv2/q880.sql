WITH
    store_sales_data AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            ss.ss_quantity,
            ss.ss_customer_id,
            ss.ss_store_id
        FROM store_sales ss
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
    ),
    web_sales_data AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            ws.ws_quantity,
            ws.ws_customer_id,
            NULL AS ss_store_id
        FROM web_sales ws
        JOIN customers c ON ws.ws_customer_id = c.c_customer_id
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ),
    combined_sales AS (
        SELECT
            i_category_id,
            i_category_name,
            ss_quantity AS quantity,
            ss_customer_id AS customer_id,
            ss_store_id
        FROM store_sales_data
        UNION ALL
        SELECT
            i_category_id,
            i_category_name,
            ws_quantity AS quantity,
            ws_customer_id AS customer_id,
            ss_store_id
        FROM web_sales_data
    ),
    category_sales AS (
        SELECT
            i_category_id,
            i_category_name,
            SUM(quantity) AS total_quantity,
            COUNT(DISTINCT customer_id) AS distinct_customers,
            COUNT(DISTINCT ss_store_id) FILTER (WHERE ss_store_id IS NOT NULL) AS distinct_stores
        FROM combined_sales
        GROUP BY i_category_id, i_category_name
    ),
    category_ratings AS (
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
    cs.i_category_id,
    cs.i_category_name,
    cs.total_quantity,
    cs.distinct_customers,
    cs.distinct_stores,
    cr.avg_rating,
    cr.review_count
FROM category_sales cs
LEFT JOIN category_ratings cr
    ON cs.i_category_id = cr.i_category_id
ORDER BY cs.total_quantity DESC
LIMIT 10
