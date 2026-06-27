WITH sales_with_details AS (
    SELECT
        ss.ss_quantity,
        CAST(ss.ss_ts AS timestamp) AS sale_ts,
        i.i_category_name,
        i.i_price,
        (i.i_price * ss.ss_quantity) AS revenue,
        ss.ss_customer_id,
        ss.ss_item_id
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
),
category_monthly AS (
    SELECT
        i_category_name,
        date_trunc('month', sale_ts) AS sale_month,
        SUM(ss_quantity) AS total_quantity,
        SUM(revenue) AS total_revenue,
        AVG(i_price) AS avg_item_price,
        COUNT(DISTINCT ss_customer_id) AS distinct_customers,
        COUNT(DISTINCT ss_item_id) AS distinct_items_sold
    FROM sales_with_details
    GROUP BY i_category_name, date_trunc('month', sale_ts)
)
SELECT
    i_category_name,
    sale_month,
    total_quantity,
    total_revenue,
    avg_item_price,
    distinct_customers,
    distinct_items_sold,
    ROW_NUMBER() OVER (PARTITION BY sale_month ORDER BY total_revenue DESC) AS revenue_rank
FROM category_monthly
ORDER BY sale_month DESC, total_revenue DESC
LIMIT 50
