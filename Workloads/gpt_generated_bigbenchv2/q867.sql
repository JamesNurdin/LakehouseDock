WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_item_id AS item_id,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id,
        ss.ss_transaction_id AS transaction_id,
        i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_agg AS (
    SELECT
        CAST(NULL AS bigint) AS store_id,
        i.i_item_id AS item_id,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id,
        ws.ws_transaction_id AS transaction_id,
        i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
sales_combined AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
item_ratings AS (
    SELECT
        i.i_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sales_with_rating AS (
    SELECT
        sc.store_id,
        sc.category_id,
        sc.category_name,
        sc.quantity,
        sc.customer_id,
        sc.transaction_id,
        sc.price,
        ir.avg_rating
    FROM sales_combined sc
    LEFT JOIN item_ratings ir ON sc.item_id = ir.item_id
)
SELECT
    COALESCE(s.s_store_name, 'Online') AS store_name,
    sc.category_name AS category_name,
    SUM(sc.quantity) AS total_quantity_sold,
    SUM(sc.quantity * sc.price) AS total_revenue,
    AVG(sc.avg_rating) AS avg_item_rating,
    COUNT(DISTINCT sc.customer_id) AS distinct_customers,
    COUNT(DISTINCT sc.transaction_id) AS total_transactions
FROM sales_with_rating sc
LEFT JOIN stores s ON sc.store_id = s.s_store_id
GROUP BY COALESCE(s.s_store_name, 'Online'), sc.category_name
ORDER BY total_revenue DESC
LIMIT 10
