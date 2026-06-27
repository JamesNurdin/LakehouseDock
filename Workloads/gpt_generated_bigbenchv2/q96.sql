WITH store_sales_agg AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity_store,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue_store,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers_store
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_quantity_web,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue_web,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers_web
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
)
SELECT
    COALESCE(s.s_store_name, 'Online') AS store_name,
    COALESCE(s.i_category_name, w.i_category_name) AS category_name,
    COALESCE(s.total_quantity_store, 0) + COALESCE(w.total_quantity_web, 0) AS total_quantity,
    COALESCE(s.total_revenue_store, 0) + COALESCE(w.total_revenue_web, 0) AS total_revenue,
    COALESCE(s.distinct_customers_store, 0) + COALESCE(w.distinct_customers_web, 0) AS distinct_customers,
    r.avg_rating,
    r.review_count
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w
    ON s.i_category_name = w.i_category_name
FULL OUTER JOIN reviews_agg r
    ON COALESCE(s.i_category_name, w.i_category_name) = r.i_category_name
ORDER BY total_revenue DESC
LIMIT 20
