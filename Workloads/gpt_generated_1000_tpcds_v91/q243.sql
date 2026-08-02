SELECT
  s.s_store_id,
  s.s_store_name,
  s.s_state,
  t.t_hour,
  c.c_customer_id,
  c.c_last_name,
  cd.cd_education_status,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  cr.cr_return_amount,
  cr.cr_return_tax,
  cr.cr_return_ship_cost,
  sr.sr_return_amt,
  sr.sr_net_loss,
  ws.ws_sales_price,
  ws.ws_ext_sales_price,
  wp.wp_url,
  CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_amount_category,
  (SELECT SUM(ws2.ws_ext_sales_price)
     FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = c.c_customer_sk) AS total_customer_sales,
  RANK() OVER (PARTITION BY s.s_state ORDER BY sr.sr_net_loss DESC) AS net_loss_rank
FROM store_returns sr
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
CROSS JOIN LATERAL (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
      FROM income_band
     WHERE ib_income_band_sk = hd.hd_income_band_sk
) ib
JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
    AND cr.cr_refunded_customer_sk = c.c_customer_sk
    AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE t.t_hour BETWEEN 8 AND 17
  AND s.s_state = 'CA'
  AND c.c_birth_month = 7
  AND cd.cd_education_status IN ('College', '2 yr Degree')
  AND ib.ib_lower_bound >= 50000
  AND cr.cr_return_amount > 20.00
  AND ws.ws_sales_price > 0
  AND sr.sr_return_quantity > 0
  AND NOT EXISTS (
        SELECT 1
          FROM catalog_returns cr_ex
         WHERE cr_ex.cr_refunded_customer_sk = c.c_customer_sk
           AND cr_ex.cr_reversed_charge > 150
    )
ORDER BY net_loss_rank ASC, s.s_store_id
LIMIT 100
