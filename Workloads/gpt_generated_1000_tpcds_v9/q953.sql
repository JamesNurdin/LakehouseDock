SELECT
  s.s_store_id,
  s.s_city,
  cc.cc_name,
  cp.cp_type,
  ws.ws_sold_date_sk,
  ws.ws_item_sk,
  ws.ws_net_profit,
  SUM(ws.ws_net_profit) OVER (
    PARTITION BY s.s_store_id
    ORDER BY ws.ws_sold_date_sk
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_store_profit,
  RANK() OVER (PARTITION BY s.s_store_id ORDER BY ws.ws_net_profit DESC) AS profit_rank,
  CASE
    WHEN ws.ws_net_profit > (
      SELECT AVG(ws2.ws_net_profit)
      FROM web_sales ws2
      WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
    ) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS profit_vs_avg_warehouse,
  cr.cr_return_amount,
  (
    SELECT COUNT(DISTINCT cp2.cp_catalog_page_id)
    FROM catalog_returns cr2
    JOIN catalog_page cp2 ON cr2.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
  ) AS distinct_pages_per_call_center
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_store_sk = s.s_store_sk
  AND sr.sr_item_sk = ss.ss_item_sk
  AND sr.sr_cdemo_sk = cd.cd_demo_sk
  AND sr.sr_hdemo_sk = hd.hd_demo_sk
  AND sr.sr_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
  AND cr.cr_returning_addr_sk = ca.ca_address_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  AND ws.ws_bill_addr_sk = ca.ca_address_sk
  AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
  cc.cc_employees > 100000
  AND s.s_state = 'CA'
  AND wp.wp_image_count >= 3
  AND ws.ws_net_profit > 0
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
ORDER BY
  s.s_store_id,
  profit_rank
LIMIT 100
