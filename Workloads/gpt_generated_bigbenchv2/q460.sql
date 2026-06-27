WITH store_category_sales AS (
    SELECT
        stores.s_store_id,
        stores.s_store_name,
        items.i_category_id,
        items.i_category_name,
        sum(store_sales.ss_quantity) AS total_quantity,
        sum(store_sales.ss_quantity * items.i_price) AS total_revenue,
        avg(items.i_price) AS avg_price,
        count(DISTINCT customers.c_customer_id) AS distinct_customers
    FROM store_sales
    JOIN stores   ON store_sales.ss_store_id = stores.s_store_id
    JOIN items    ON store_sales.ss_item_id   = items.i_item_id
    JOIN customers ON store_sales.ss_customer_id = customers.c_customer_id
    GROUP BY
        stores.s_store_id,
        stores.s_store_name,
        items.i_category_id,
        items.i_category_name
)
SELECT
    s_store_id,
    s_store_name,
    i_category_id,
    i_category_name,
    total_quantity,
    total_revenue,
    avg_price,
    distinct_customers,
    rank() OVER (PARTITION BY s_store_id ORDER BY total_revenue DESC) AS revenue_rank
FROM store_category_sales
ORDER BY s_store_id, revenue_rank
