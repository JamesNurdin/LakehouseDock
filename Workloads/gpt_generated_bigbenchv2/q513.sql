WITH category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_sales_amount,
        AVG(i.i_price - i.i_comp_price) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name
)
SELECT
    cs.s_store_name,
    cs.i_category_name,
    cs.total_quantity,
    cs.total_sales_amount,
    cs.avg_discount,
    cs.distinct_customers,
    RANK() OVER (PARTITION BY cs.s_store_name ORDER BY cs.total_sales_amount DESC) AS category_rank
FROM category_sales cs
WHERE cs.total_quantity > 0
ORDER BY cs.s_store_name, category_rank
