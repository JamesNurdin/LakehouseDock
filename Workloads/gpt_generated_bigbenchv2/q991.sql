WITH sales_detail AS (
    SELECT
        ss.ss_transaction_id,
        ss.ss_customer_id,
        ss.ss_store_id AS ss_store_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_price,
        i.i_category_id,
        i.i_category_name,
        c.c_name AS customer_name,
        s.s_store_name,
        (ss.ss_quantity * i.i_price) AS revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
customer_store_agg AS (
    SELECT
        ss_store_id,
        s_store_name,
        ss_customer_id,
        customer_name,
        SUM(revenue) AS total_spent,
        COUNT(DISTINCT ss_item_id) AS distinct_items,
        SUM(ss_quantity) AS total_quantity
    FROM sales_detail
    GROUP BY ss_store_id, s_store_name, ss_customer_id, customer_name
),
ranked_customers AS (
    SELECT
        ss_store_id,
        s_store_name,
        ss_customer_id,
        customer_name,
        total_spent,
        distinct_items,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ss_store_id ORDER BY total_spent DESC) AS spend_rank
    FROM customer_store_agg
)
SELECT
    s_store_name,
    customer_name,
    total_spent,
    distinct_items,
    total_quantity,
    spend_rank
FROM ranked_customers
WHERE spend_rank <= 5
ORDER BY s_store_name, spend_rank
