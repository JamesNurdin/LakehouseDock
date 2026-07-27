WITH joined_data AS (
   SELECT
       d.d_date,
       i.i_item_id,
       i.i_product_name,
       w.w_warehouse_name,
       s.s_store_name,
       inv.inv_quantity_on_hand,
       i.i_size,
       w.w_city,
       d.d_year
   FROM inventory inv
   JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
     AND i.i_size = 'large'
     AND w.w_city = 'Greenwood'
)
SELECT
    d_date,
    i_item_id,
    i_product_name,
    w_warehouse_name,
    inv_quantity_on_hand,
    SUM(inv_quantity_on_hand) OVER (
        PARTITION BY d_date
        ORDER BY inv_quantity_on_hand DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_qty_by_day,
    RANK() OVER (PARTITION BY d_date ORDER BY inv_quantity_on_hand DESC) AS qty_rank,
    CASE
        WHEN inv_quantity_on_hand >= 1000 THEN 'High'
        WHEN inv_quantity_on_hand >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS qty_category
FROM joined_data
ORDER BY d_date DESC, qty_rank
LIMIT 100
