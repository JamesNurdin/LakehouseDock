WITH category_sales AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        AVG(i.i_price) AS avg_item_price
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    GROUP BY s.s_store_name, i.i_category_name
),
ranked_category_sales AS (
    SELECT
        s_store_name,
        i_category_name,
        total_revenue,
        total_quantity,
        distinct_customers,
        avg_item_price,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_revenue DESC) AS category_rank
    FROM category_sales
)
SELECT
    s_store_name,
    i_category_name,
    total_revenue,
    total_quantity,
    distinct_customers,
    avg_item_price,
    category_rank
FROM ranked_category_sales
WHERE category_rank <= 5
ORDER BY s_store_name, category_rank
