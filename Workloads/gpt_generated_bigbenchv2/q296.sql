WITH all_sales AS (
    SELECT
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        ss_store_id AS store_id,
        ss_customer_id AS customer_id,
        'store' AS sale_channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        NULL AS store_id,
        ws_customer_id AS customer_id,
        'web' AS sale_channel
    FROM web_sales
), sales_with_details AS (
    SELECT
        a.item_id,
        a.quantity,
        a.store_id,
        a.customer_id,
        i.i_name,
        i.i_category_name,
        i.i_price,
        s.s_store_name
    FROM all_sales a
    JOIN items i
        ON a.item_id = i.i_item_id
    LEFT JOIN stores s
        ON a.store_id = s.s_store_id
)
SELECT
    COALESCE(sales_with_details.s_store_name, 'Online') AS store_name,
    sales_with_details.i_category_name,
    SUM(sales_with_details.quantity) AS total_quantity,
    SUM(sales_with_details.quantity * sales_with_details.i_price) AS total_sales_amount,
    COUNT(DISTINCT sales_with_details.customer_id) AS distinct_customers,
    ROUND(AVG(r.pr_rating), 2) AS avg_rating,
    COUNT(DISTINCT r.pr_review_id) AS review_count
FROM sales_with_details
LEFT JOIN product_reviews r
    ON sales_with_details.item_id = r.pr_item_id
GROUP BY
    COALESCE(sales_with_details.s_store_name, 'Online'),
    sales_with_details.i_category_name
ORDER BY total_quantity DESC
LIMIT 10
