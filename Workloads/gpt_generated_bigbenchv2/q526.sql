WITH sales AS (
    SELECT
        ss_transaction_id,
        ss_customer_id,
        ss_store_id,
        ss_item_id,
        ss_quantity,
        CAST(parse_datetime(ss_ts, '%Y-%m-%d %H:%i:%s') AS timestamp) AS sale_ts,
        CAST(parse_datetime(ss_ts, '%Y-%m-%d %H:%i:%s') AS date) AS sale_date
    FROM store_sales
),
agg AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        s.ss_store_id,
        SUM(s.ss_quantity) AS total_quantity,
        COUNT(DISTINCT s.ss_item_id) AS distinct_items,
        MIN(s.sale_date) AS first_purchase_date,
        MAX(s.sale_date) AS last_purchase_date,
        COUNT(*) AS transaction_count
    FROM sales s
    JOIN customers c
        ON s.ss_customer_id = c.c_customer_id
    GROUP BY
        c.c_customer_id,
        c.c_name,
        s.ss_store_id
),
ranked AS (
    SELECT
        c_customer_id,
        c_name,
        ss_store_id,
        total_quantity,
        distinct_items,
        first_purchase_date,
        last_purchase_date,
        transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_id ORDER BY total_quantity DESC) AS store_customer_rank
    FROM agg
)
SELECT
    c_customer_id,
    c_name,
    ss_store_id,
    total_quantity,
    distinct_items,
    first_purchase_date,
    last_purchase_date,
    transaction_count,
    store_customer_rank
FROM ranked
WHERE store_customer_rank <= 5
ORDER BY ss_store_id, store_customer_rank
