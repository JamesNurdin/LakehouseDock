WITH category_sales AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS unique_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category_name
)
SELECT
    s_store_name,
    i_category_name,
    total_sales,
    total_quantity,
    unique_customers,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS category_rank
FROM category_sales
WHERE total_sales > 500
ORDER BY s_store_name, category_rank
