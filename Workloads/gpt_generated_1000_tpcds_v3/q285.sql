WITH base AS (
  SELECT
    s.s_store_id,
    s.s_state,
    d.d_year,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(sr.sr_net_loss) AS store_return_loss,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    AVG(ib.ib_lower_bound) AS avg_income_lower,
    SUM(ss.ss_quantity) + SUM(cs.cs_quantity) AS total_quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_return_time_sk = t.t_time_sk
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_sold_time_sk = t.t_time_sk
    AND cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_returned_time_sk = t.t_time_sk
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    AND wp.wp_creation_date_sk = d.d_date_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND cd.cd_credit_rating = 'Good'
    AND hd.hd_buy_potential = '500-1000'
    AND ib.ib_lower_bound >= 50000
    AND s.s_state = 'CA'
    AND inv.inv_quantity_on_hand > 0
  GROUP BY s.s_store_id, s.s_state, d.d_year
)
SELECT
  b.s_store_id,
  b.s_state,
  b.d_year,
  b.store_net_profit,
  b.catalog_net_profit,
  b.store_return_loss,
  b.catalog_return_loss,
  b.total_inventory_qty,
  b.distinct_pages,
  b.avg_income_lower,
  b.total_quantity,
  (b.store_net_profit + b.catalog_net_profit - b.store_return_loss - b.catalog_return_loss) / nullif(b.total_quantity, 0) AS profit_per_quantity,
  (SELECT AVG(store_net_profit + catalog_net_profit) FROM base) AS overall_avg_profit
FROM base b
WHERE (b.store_net_profit + b.catalog_net_profit) > (SELECT AVG(store_net_profit + catalog_net_profit) FROM base)
ORDER BY profit_per_quantity DESC
LIMIT 100
