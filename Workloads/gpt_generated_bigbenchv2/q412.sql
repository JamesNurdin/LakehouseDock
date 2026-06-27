WITH sales_with_price AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        ss.ss_transaction_id,
        ss.ss_customer_id,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales AS ss
    JOIN items AS i
        ON ss.ss_item_id = i.i_item_id
)
SELECT
    s.i_category_id,
    s.i_category_name,
    s.ss_store_id,
    SUM(s.revenue) AS total_revenue,
    SUM(s.ss_quantity) AS total_quantity,
    COUNT(DISTINCT s.ss_transaction_id) AS distinct_transactions,
    COUNT(DISTINCT s.ss_customer_id) AS distinct_customers,
    AVG(s.i_price) AS average_item_price
FROM sales_with_price AS s
GROUP BY
    s.i_category_id,
    s.i_category_name,
    s.ss_store_id
ORDER BY total_revenue DESC
LIMIT 100
