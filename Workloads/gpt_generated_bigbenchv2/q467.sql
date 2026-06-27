-- Revenue and quantity per item per store, ranking items within each store by total revenue
WITH sales_items AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_name,
        i.i_category_name,
        i.i_price,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
),
store_item_agg AS (
    SELECT
        si.ss_store_id,
        si.i_category_name,
        si.i_name,
        SUM(si.revenue) AS total_revenue,
        SUM(si.ss_quantity) AS total_quantity
    FROM sales_items si
    GROUP BY
        si.ss_store_id,
        si.i_category_name,
        si.i_name
    HAVING SUM(si.revenue) > 1000
)
SELECT
    agg.ss_store_id,
    agg.i_category_name,
    agg.i_name,
    agg.total_revenue,
    agg.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY agg.ss_store_id ORDER BY agg.total_revenue DESC) AS rank_per_store
FROM store_item_agg agg
ORDER BY agg.ss_store_id, rank_per_store
LIMIT 50
