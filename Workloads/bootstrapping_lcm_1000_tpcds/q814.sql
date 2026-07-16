SELECT
    cr.cr_warehouse_sk,
    s.s_store_sk,
    d_return.d_year AS return_year,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(CASE WHEN d_return.d_month_seq = d_sold.d_month_seq THEN 1 ELSE 0 END) AS same_month_sales_return_cnt,
    SUM(CASE WHEN d_ship.d_week_seq - d_sold.d_week_seq > 0 THEN d_ship.d_week_seq - d_sold.d_week_seq ELSE 0 END) AS ship_delay_weeks,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(cs.cs_ext_tax) AS total_tax_amount,
    COUNT(*) AS total_rows
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_item_sk = cs.cs_item_sk
  AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN inventory inv
  ON inv.inv_date_sk = d_return.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year BETWEEN 2000 AND 2005
GROUP BY
    cr.cr_warehouse_sk,
    s.s_store_sk,
    d_return.d_year
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
