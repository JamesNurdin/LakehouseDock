WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name
),
store_customers AS (
    SELECT DISTINCT
        ss.ss_store_id,
        ss.ss_customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
),
web_sales_by_store AS (
    SELECT
        sc.ss_store_id,
        SUM(ws.ws_quantity) AS web_quantity
    FROM store_customers sc
    JOIN web_sales ws ON sc.ss_customer_id = ws.ws_customer_id
    GROUP BY sc.ss_store_id
),
category_reviews AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_category_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    ss.s_store_name,
    ss.i_category_name,
    ss.total_quantity,
    ss.total_revenue,
    COALESCE(wb.web_quantity, 0) AS web_quantity,
    COALESCE(cr.avg_category_rating, 0) AS avg_category_rating,
    COALESCE(cr.review_count, 0) AS review_count
FROM store_sales_agg ss
LEFT JOIN web_sales_by_store wb ON ss.s_store_id = wb.ss_store_id
LEFT JOIN category_reviews cr ON ss.i_category_id = cr.i_category_id
ORDER BY ss.total_revenue DESC
LIMIT 100
