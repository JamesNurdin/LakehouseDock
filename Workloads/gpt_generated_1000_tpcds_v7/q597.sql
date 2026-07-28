/* Goal: Summarize net loss and inventory by catalog department, warehouse city, and year for non‑holiday returns in 2001 */
SELECT
    cp.cp_department,
    w1.w_city,
    d_sr.d_year,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
FROM store_returns sr
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_close
    ON s.s_closed_date_sk = d_store_close.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN warehouse w1
    ON cr.cr_warehouse_sk = w1.w_warehouse_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sr.d_date_sk
   AND inv.inv_warehouse_sk = w1.w_warehouse_sk
WHERE d_sr.d_year = 2001
  AND d_sr.d_holiday = 'N'
GROUP BY cp.cp_department, w1.w_city, d_sr.d_year
ORDER BY total_store_net_loss DESC
LIMIT 10
