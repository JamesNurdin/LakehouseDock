WITH sales_enriched AS (
    SELECT
        ss.ss_transaction_id,
        ss.ss_quantity,
        ss.ss_customer_id,
        ss.ss_store_id,
        ss.ss_item_id,
        i.i_price,
        i.i_category,
        i.i_name,
        c.c_customer_id,
        c.c_name,
        s.s_store_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
)
SELECT
    sse.s_store_name,
    SUM(sse.ss_quantity * sse.i_price) AS total_sales_amount,
    SUM(sse.ss_quantity) AS total_quantity_sold,
    COUNT(DISTINCT sse.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT sse.i_category) AS distinct_categories
FROM sales_enriched sse
GROUP BY sse.s_store_name
ORDER BY total_sales_amount DESC
LIMIT 10
