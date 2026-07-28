WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_date_sk IN (
          SELECT d_date_sk
          FROM date_dim
          WHERE d_year = 2000
      )
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_ext_sales_price)               AS total_sales,
    SUM(cr.cr_net_loss)                      AS total_return_loss,
    SUM(ss.ss_ext_sales_price) - SUM(cr.cr_net_loss) AS net_sales_after_returns,
    inv_agg.total_qty_on_hand                AS total_inventory_qty
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg
  ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  AND ss.ss_list_price > 50
  AND ss.ss_quantity >= 1
  AND w.w_state = 'CA'
  AND d.d_month_seq IN (1, 2, 3, 4, 5)
  AND cr.cr_return_quantity > 0
GROUP BY w.w_warehouse_name, d.d_year, d.d_month_seq, inv_agg.total_qty_on_hand
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY net_sales_after_returns DESC
LIMIT 100
