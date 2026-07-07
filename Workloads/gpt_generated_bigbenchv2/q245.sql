WITH sales_detail AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        ss.ss_item_id,
        i.i_category,
        ss.ss_quantity,
        ss.ss_customer_id,
        i.i_price,
        (ss.ss_quantity * i.i_price) AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
)
SELECT
    agg.s_store_name,
    agg.i_category,
    agg.total_revenue,
    agg.total_quantity,
    agg.distinct_customers,
    RANK() OVER (PARTITION BY agg.s_store_name ORDER BY agg.total_revenue DESC) AS category_rank
FROM (
    SELECT
        sd.s_store_name,
        sd.i_category,
        SUM(sd.revenue) AS total_revenue,
        SUM(sd.ss_quantity) AS total_quantity,
        COUNT(DISTINCT sd.ss_customer_id) AS distinct_customers
    FROM sales_detail sd
    GROUP BY sd.s_store_name, sd.i_category
) AS agg
ORDER BY agg.s_store_name, agg.total_revenue DESC
