WITH store_sales_detail AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        s.s_store_name AS store_name,
        i.i_price,
        i.i_category_name,
        i.i_name
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_detail AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        NULL AS store_name,
        i.i_price,
        i.i_category_name,
        i.i_name
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
all_sales AS (
    SELECT * FROM store_sales_detail
    UNION ALL
    SELECT * FROM web_sales_detail
),
rating_summary AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    COALESCE(a.store_name, 'Online') AS sales_channel,
    a.i_category_name,
    a.i_name,
    SUM(a.quantity) AS total_quantity,
    SUM(a.quantity * a.i_price) AS total_revenue,
    COUNT(DISTINCT a.customer_id) AS distinct_customers,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count
FROM all_sales a
LEFT JOIN rating_summary r ON a.item_id = r.pr_item_id
GROUP BY
    COALESCE(a.store_name, 'Online'),
    a.i_category_name,
    a.i_name,
    r.avg_rating,
    r.review_count
ORDER BY total_revenue DESC
LIMIT 20
