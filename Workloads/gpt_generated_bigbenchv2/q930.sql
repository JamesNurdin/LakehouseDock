/*
  Revenue share and ranking of item categories per store, including total revenue,
  total quantity sold and distinct customer count.
*/
WITH aggregated_sales AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS category_revenue,
        SUM(ss.ss_quantity) AS category_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category_name
)
SELECT
    aggregated_sales.s_store_name,
    aggregated_sales.i_category_name,
    aggregated_sales.category_revenue,
    aggregated_sales.category_quantity,
    aggregated_sales.distinct_customers,
    aggregated_sales.category_revenue * 1.0
        / SUM(aggregated_sales.category_revenue) OVER (PARTITION BY aggregated_sales.s_store_name) AS revenue_share,
    ROW_NUMBER() OVER (PARTITION BY aggregated_sales.s_store_name ORDER BY aggregated_sales.category_revenue DESC) AS category_rank
FROM aggregated_sales
ORDER BY aggregated_sales.s_store_name, category_rank
LIMIT 100
