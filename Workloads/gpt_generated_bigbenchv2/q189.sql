WITH
    store_sales_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity * i.i_price) AS revenue,
            SUM(ss.ss_quantity) AS quantity,
            COUNT(DISTINCT ss.ss_customer_id) AS customer_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity * i.i_price) AS revenue,
            SUM(ws.ws_quantity) AS quantity,
            COUNT(DISTINCT ws.ws_customer_id) AS customer_count
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    category_sales AS (
        SELECT
            COALESCE(s.i_category_id, w.i_category_id) AS category_id,
            COALESCE(s.i_category_name, w.i_category_name) AS category_name,
            COALESCE(s.revenue, 0) + COALESCE(w.revenue, 0) AS total_revenue,
            COALESCE(s.quantity, 0) + COALESCE(w.quantity, 0) AS total_quantity,
            COALESCE(s.customer_count, 0) + COALESCE(w.customer_count, 0) AS total_customers
        FROM store_sales_agg s
        FULL OUTER JOIN web_sales_agg w
            ON s.i_category_id = w.i_category_id
    ),
    category_reviews AS (
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
    cs.category_id,
    cs.category_name,
    cs.total_revenue,
    cs.total_quantity,
    cs.total_customers,
    cr.avg_rating,
    cr.review_count
FROM category_sales cs
LEFT JOIN category_reviews cr
    ON cs.category_id = cr.i_category_id
ORDER BY cs.total_revenue DESC
LIMIT 10
