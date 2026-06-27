WITH
    category_ratings AS (
        SELECT
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_name
    ),
    store_sales_agg AS (
        SELECT
            s.s_store_name,
            i.i_category_name,
            SUM(ss.ss_quantity) AS total_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
        FROM store_sales ss
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY s.s_store_name, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            'Online' AS s_store_name,
            i.i_category_name,
            SUM(ws.ws_quantity) AS total_quantity,
            SUM(ws.ws_quantity * i.i_price) AS total_revenue,
            COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
        FROM web_sales ws
        JOIN customers c ON ws.ws_customer_id = c.c_customer_id
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_name
    ),
    combined_sales AS (
        SELECT * FROM store_sales_agg
        UNION ALL
        SELECT * FROM web_sales_agg
    )
SELECT
    cs.s_store_name,
    cs.i_category_name,
    SUM(cs.total_quantity) AS total_quantity,
    SUM(cs.total_revenue) AS total_revenue,
    SUM(cs.distinct_customers) AS distinct_customers,
    cr.avg_rating
FROM combined_sales cs
LEFT JOIN category_ratings cr ON cr.i_category_name = cs.i_category_name
GROUP BY cs.s_store_name, cs.i_category_name, cr.avg_rating
ORDER BY total_revenue DESC
LIMIT 10
