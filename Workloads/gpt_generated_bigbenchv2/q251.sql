WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        ss.ss_quantity AS sales_quantity,
        ss.ss_customer_id AS sales_customer_id,
        ss.ss_store_id AS sales_store_id,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        ws.ws_quantity AS sales_quantity,
        ws.ws_customer_id AS sales_customer_id,
        NULL AS sales_store_id,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
combined_sales AS (
    SELECT
        i_item_id,
        i_name,
        i_category_id,
        i_category_name,
        i_price,
        sales_quantity,
        sales_customer_id,
        sales_store_id,
        sales_channel
    FROM item_sales
    UNION ALL
    SELECT
        i_item_id,
        i_name,
        i_category_id,
        i_category_name,
        i_price,
        sales_quantity,
        sales_customer_id,
        sales_store_id,
        sales_channel
    FROM web_sales_agg
),
rating_per_item AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    cs.i_item_id,
    cs.i_name,
    cs.i_category_name,
    SUM(cs.sales_quantity) AS total_quantity_sold,
    SUM(cs.sales_quantity * cs.i_price) AS total_revenue,
    COUNT(DISTINCT cs.sales_customer_id) AS distinct_customers,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count
FROM combined_sales cs
LEFT JOIN rating_per_item r ON cs.i_item_id = r.pr_item_id
GROUP BY
    cs.i_item_id,
    cs.i_name,
    cs.i_category_name,
    r.avg_rating,
    r.review_count
ORDER BY total_revenue DESC
LIMIT 10
