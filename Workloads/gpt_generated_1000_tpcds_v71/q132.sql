SELECT
  s.s_store_name,
  s.s_state,
  i.i_class,
  i.i_units,
  cc.cc_market_manager,
  w.w_city,
  SUM(ss.ss_net_profit) AS total_store_profit,
  COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
  AVG(ss.ss_quantity) AS avg_quantity_sold,
  MAX(sr.sr_net_loss) AS max_store_return_loss,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(ws.ws_net_profit) AS total_web_profit
FROM store_sales ss
JOIN time_dim t_sales
  ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim t_store_ret
  ON sr.sr_return_time_sk = t_store_ret.t_time_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
JOIN time_dim t_cat_ret
  ON cr.cr_returned_time_sk = t_cat_ret.t_time_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim t_web
  ON ws.ws_sold_time_sk = t_web.t_time_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE i.i_class = 'sports-apparel'
  AND i.i_units = 'Each'
  AND ib.ib_lower_bound >= 50000
  AND t_sales.t_hour BETWEEN 8 AND 12
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
  AND w.w_state = 'CA'
  AND s.s_state = 'TX'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_net_loss > 5000
      )
GROUP BY
  s.s_store_name,
  s.s_state,
  i.i_class,
  i.i_units,
  cc.cc_market_manager,
  w.w_city
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY total_store_profit DESC
LIMIT 100
