WITH sales_detail AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        ss.ss_customer_id,
        ss.ss_quantity,
        i.i_price,
        i.i_comp_price,
        i.i_category_name,
        s.s_store_name
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
),
store_category_sales AS (
    SELECT
        s_store_name,
        i_category_name,
        SUM(ss_quantity * i_price) AS total_revenue,
        SUM(ss_quantity) AS total_units,
        COUNT(DISTINCT ss_customer_id) AS distinct_customers,
        SUM(CASE WHEN i_comp_price < i_price THEN ss_quantity * (i_price - i_comp_price) ELSE 0 END) AS lost_revenue_due_to_competition
    FROM sales_detail
    GROUP BY s_store_name, i_category_name
    HAVING SUM(ss_quantity * i_price) > 0
)
SELECT
    s_store_name,
    i_category_name,
    total_revenue,
    total_units,
    distinct_customers,
    lost_revenue_due_to_competition,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_revenue DESC) AS category_rank
FROM store_category_sales
ORDER BY s_store_name, category_rank
LIMIT 200
