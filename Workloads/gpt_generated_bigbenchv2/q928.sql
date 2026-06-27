WITH combined_sales AS (
    SELECT
        ss_transaction_id AS transaction_id,
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        ss_ts AS ts,
        'store' AS sales_channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_transaction_id AS transaction_id,
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        ws_ts AS ts,
        'web' AS sales_channel
    FROM web_sales
),
customer_category_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_name,
        SUM(i.i_price * cs.quantity) AS total_spent,
        SUM(cs.quantity) AS total_quantity,
        COUNT(DISTINCT cs.transaction_id) AS transaction_count,
        COUNT(DISTINCT i.i_item_id) AS distinct_items
    FROM combined_sales cs
    JOIN customers c ON cs.customer_id = c.c_customer_id
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY
        c.c_customer_id,
        c.c_name,
        i.i_category_name
)
SELECT
    ccs.c_customer_id,
    ccs.c_name,
    ccs.i_category_name,
    ccs.total_spent,
    ccs.total_quantity,
    ccs.transaction_count,
    ccs.distinct_items,
    ROW_NUMBER() OVER (PARTITION BY ccs.c_customer_id ORDER BY ccs.total_spent DESC) AS category_spend_rank
FROM customer_category_sales ccs
ORDER BY ccs.total_spent DESC
LIMIT 200
