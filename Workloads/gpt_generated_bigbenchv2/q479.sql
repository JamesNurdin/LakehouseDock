WITH
    store_sales_agg AS (
        SELECT
            i.i_category_id AS category_id,
            i.i_category_name AS category_name,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_category_id AS category_id,
            i.i_category_name AS category_name,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    category_ratings AS (
        SELECT
            i.i_category_id AS category_id,
            i.i_category_name AS category_name,
            AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    distinct_customers AS (
        SELECT
            i.i_category_id AS category_id,
            i.i_category_name AS category_name,
            ss.ss_customer_id AS c_customer_id
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id

        UNION

        SELECT
            i.i_category_id AS category_id,
            i.i_category_name AS category_name,
            ws.ws_customer_id AS c_customer_id
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ),
    distinct_customers_agg AS (
        SELECT
            category_id,
            category_name,
            COUNT(DISTINCT c_customer_id) AS distinct_customers
        FROM distinct_customers
        GROUP BY category_id, category_name
    )
SELECT
    COALESCE(ss.category_id, ws.category_id, cr.category_id, dc.category_id) AS category_id,
    COALESCE(ss.category_name, ws.category_name, cr.category_name, dc.category_name) AS category_name,
    COALESCE(ss.store_revenue, 0) AS store_revenue,
    COALESCE(ws.web_revenue, 0) AS web_revenue,
    COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) AS total_revenue,
    COALESCE(dc.distinct_customers, 0) AS distinct_customers,
    COALESCE(cr.avg_rating, 0) AS avg_rating
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.category_id = ws.category_id
FULL OUTER JOIN category_ratings cr ON COALESCE(ss.category_id, ws.category_id) = cr.category_id
FULL OUTER JOIN distinct_customers_agg dc ON COALESCE(ss.category_id, ws.category_id) = dc.category_id
ORDER BY total_revenue DESC
LIMIT 100
