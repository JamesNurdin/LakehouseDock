WITH sales AS (
    SELECT
        ss_customer_id,
        ss_item_id,
        ss_quantity,
        ss_ts,
        'store' AS sales_channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_customer_id AS ss_customer_id,
        ws_item_id AS ss_item_id,
        ws_quantity AS ss_quantity,
        ws_ts AS ss_ts,
        'web' AS sales_channel
    FROM web_sales
),
customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        s.ss_item_id,
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        s.ss_quantity,
        s.sales_channel
    FROM sales s
    JOIN customers c ON s.ss_customer_id = c.c_customer_id
    JOIN items i ON s.ss_item_id = i.i_item_id
)
SELECT
    cs.c_customer_id,
    cs.c_name,
    cs.i_category_id,
    cs.i_category_name,
    SUM(cs.ss_quantity) AS total_quantity,
    SUM(cs.ss_quantity * cs.i_price) AS total_sales_amount,
    COUNT(DISTINCT cs.i_item_id) AS distinct_items_purchased,
    AVG(pr.pr_rating) AS avg_rating,
    COUNT(pr.pr_review_id) AS review_count
FROM customer_sales cs
LEFT JOIN product_reviews pr ON pr.pr_item_id = cs.i_item_id
GROUP BY
    cs.c_customer_id,
    cs.c_name,
    cs.i_category_id,
    cs.i_category_name
ORDER BY total_sales_amount DESC
LIMIT 20
