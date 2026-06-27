WITH aggregated_items AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS item_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
ranked_items AS (
    SELECT
        ai.ss_store_id,
        ai.ss_item_id,
        ai.item_quantity,
        ROW_NUMBER() OVER (PARTITION BY ai.ss_store_id ORDER BY ai.item_quantity DESC) AS rn
    FROM aggregated_items ai
),
store_summary AS (
    SELECT
        ss.ss_store_id,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_id
),
customer_spending AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        SUM(ss.ss_quantity) AS customer_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_customer_id
),
ranked_customers AS (
    SELECT
        cs.ss_store_id,
        cs.ss_customer_id,
        cs.customer_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.customer_quantity DESC) AS rn
    FROM customer_spending cs
)
SELECT
    s.s_store_name,
    ss.transaction_count,
    ss.total_quantity,
    ss.distinct_customers,
    ri.ss_item_id AS top_item_id,
    ri.item_quantity AS top_item_quantity,
    c.c_name AS top_customer_name,
    rc.customer_quantity AS top_customer_quantity
FROM store_summary ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
JOIN ranked_items ri ON ss.ss_store_id = ri.ss_store_id AND ri.rn = 1
JOIN ranked_customers rc ON ss.ss_store_id = rc.ss_store_id AND rc.rn = 1
JOIN customers c ON rc.ss_customer_id = c.c_customer_id
ORDER BY ss.total_quantity DESC
LIMIT 10
