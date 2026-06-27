WITH store_sales_cte AS (
    SELECT
        ss.ss_customer_id,
        ss.ss_item_id,
        ss.ss_quantity
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
),
web_sales_cte AS (
    SELECT
        ws.ws_customer_id,
        ws.ws_item_id,
        ws.ws_quantity
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
all_sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id   AS item_id,
           ss_quantity  AS quantity
    FROM store_sales_cte
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id   AS item_id,
           ws_quantity  AS quantity
    FROM web_sales_cte
),
item_reviews AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(a.quantity) AS total_quantity_sold,
    SUM(i.i_price * a.quantity) AS total_revenue,
    COUNT(DISTINCT a.customer_id) AS distinct_customers,
    AVG(ir.avg_rating) AS avg_item_rating,
    SUM(ir.review_count) AS total_review_count
FROM all_sales a
JOIN items i ON a.item_id = i.i_item_id
LEFT JOIN item_reviews ir ON i.i_item_id = ir.pr_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
