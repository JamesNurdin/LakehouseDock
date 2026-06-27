WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price
)
SELECT
    isales.i_item_id,
    isales.i_name,
    isales.i_category_name,
    isales.total_quantity,
    isales.total_revenue,
    RANK() OVER (PARTITION BY isales.i_category_name ORDER BY isales.total_revenue DESC) AS revenue_rank_in_category
FROM item_sales isales
ORDER BY isales.total_revenue DESC
LIMIT 20
