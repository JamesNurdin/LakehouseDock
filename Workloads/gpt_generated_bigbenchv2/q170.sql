WITH all_sales AS (
    SELECT
        ss_transaction_id AS sale_id,
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        ss_store_id AS store_id,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_transaction_id AS sale_id,
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        NULL AS store_id,
        'web' AS channel
    FROM web_sales
),

sales_details AS (
    SELECT
        a.sale_id,
        a.customer_id,
        a.item_id,
        a.quantity,
        a.channel,
        a.store_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        c.c_name,
        s.s_store_name AS store_name
    FROM all_sales a
    JOIN items i
        ON a.item_id = i.i_item_id
    JOIN customers c
        ON a.customer_id = c.c_customer_id
    LEFT JOIN stores s
        ON a.store_id = s.s_store_id
),

item_ratings AS (
    SELECT
        i.i_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    sd.channel,
    COALESCE(sd.store_name, 'Online') AS sales_channel,
    sd.i_category_id,
    sd.i_category_name,
    SUM(sd.quantity) AS total_quantity,
    SUM(sd.i_price * sd.quantity) AS total_revenue,
    AVG(ir.avg_rating) AS avg_item_rating,
    SUM(ir.review_count) AS total_review_count,
    COUNT(DISTINCT sd.customer_id) AS distinct_customer_count,
    COUNT(DISTINCT sd.item_id) AS distinct_item_count
FROM sales_details sd
LEFT JOIN item_ratings ir
    ON sd.item_id = ir.item_id
GROUP BY
    sd.channel,
    COALESCE(sd.store_name, 'Online'),
    sd.i_category_id,
    sd.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
