WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
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
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    ss.s_store_id,
    ss.s_store_name,
    ss.i_category_id,
    ss.i_category_name,
    ss.total_store_quantity,
    ss.total_store_revenue,
    ws.total_web_quantity,
    ws.total_web_revenue,
    ss.distinct_store_customers,
    ws.distinct_web_customers,
    rev.avg_rating,
    rev.review_count,
    ROW_NUMBER() OVER (PARTITION BY ss.s_store_id ORDER BY ss.total_store_revenue DESC) AS store_category_rank
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
    AND ss.i_category_name = ws.i_category_name
LEFT JOIN reviews_agg rev
    ON ss.i_category_id = rev.i_category_id
    AND ss.i_category_name = rev.i_category_name
ORDER BY ss.total_store_revenue DESC
LIMIT 100
