WITH sales_enriched AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        ss.ss_customer_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        i.i_class_id,
        (ss.ss_quantity * i.i_price) AS revenue,
        (ss.ss_quantity * (i.i_price - i.i_comp_price)) AS price_diff
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
)
SELECT
    se.ss_store_id,
    se.s_store_name,
    se.i_category_id,
    se.i_category_name,
    SUM(se.revenue) AS total_revenue,
    SUM(se.ss_quantity) AS total_quantity,
    ROUND(SUM(se.price_diff) / NULLIF(SUM(se.ss_quantity), 0), 2) AS avg_price_diff,
    COUNT(DISTINCT se.ss_customer_id) AS distinct_customers,
    RANK() OVER (PARTITION BY se.ss_store_id ORDER BY SUM(se.revenue) DESC) AS revenue_rank
FROM sales_enriched se
GROUP BY
    se.ss_store_id,
    se.s_store_name,
    se.i_category_id,
    se.i_category_name
ORDER BY
    se.ss_store_id,
    revenue_rank
