WITH sales_agg AS (
    SELECT
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_quantity * i.i_price) AS total_sales_amount,
        SUM(ss.ss_quantity) AS total_units_sold,
        COUNT(DISTINCT ss.ss_transaction_id) AS num_transactions
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category
)
SELECT
    s_store_name,
    i_category,
    total_sales_amount,
    total_units_sold,
    num_transactions,
    total_sales_amount / NULLIF(total_units_sold, 0) AS avg_price_per_unit
FROM sales_agg
ORDER BY total_sales_amount DESC
LIMIT 10
