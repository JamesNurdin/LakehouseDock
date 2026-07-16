SELECT
    s.s_store_id,
    s.s_store_name,
    w.w_warehouse_name,
    ds.d_year,
    ds.d_current_month,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) AS net_profit_after_returns,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    COUNT(DISTINCT CASE WHEN cr.cr_order_number IS NOT NULL THEN cr.cr_order_number END) AS total_returns,
    ROW_NUMBER() OVER (PARTITION BY ds.d_year ORDER BY SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim ds
    ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN date_dim dsh
    ON cs.cs_ship_date_sk = dsh.d_date_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
   AND cs.cs_warehouse_sk = cr.cr_warehouse_sk
LEFT JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = ds.d_date_sk
WHERE ds.d_year = 2020
  AND date_diff('day', ds.d_date, dsh.d_date) BETWEEN 0 AND 30
  AND (cr.cr_order_number IS NULL OR date_diff('day', ds.d_date, dr.d_date) <= 90)
GROUP BY
    s.s_store_id,
    s.s_store_name,
    w.w_warehouse_name,
    ds.d_year,
    ds.d_current_month
ORDER BY profit_rank
LIMIT 50
