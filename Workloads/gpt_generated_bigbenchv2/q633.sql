WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_pre AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id   AS item_id,
        ss.ss_quantity  AS quantity
    FROM store_sales ss
),
web_sales_pre AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id    AS item_id,
        ws.ws_quantity   AS quantity
    FROM web_sales ws
),
combined_sales AS (
    SELECT * FROM store_sales_pre
    UNION ALL
    SELECT * FROM web_sales_pre
)
SELECT
    c.c_customer_id,
    c.c_name,
    i.i_category_name,
    SUM(cs.quantity)                       AS total_quantity,
    SUM(cs.quantity * i.i_price)           AS total_spent,
    AVG(ir.avg_rating)                     AS avg_item_rating,
    SUM(ir.review_count)                   AS total_reviews
FROM combined_sales cs
JOIN customers c ON cs.customer_id = c.c_customer_id
JOIN items i      ON cs.item_id = i.i_item_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
GROUP BY c.c_customer_id, c.c_name, i.i_category_name
ORDER BY total_spent DESC
LIMIT 20
