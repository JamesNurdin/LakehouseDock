WITH
  item_tbl AS (
    SELECT *
    FROM item
  )
SELECT
  i.i_category,
  ca_bill.ca_state,
  sm_ret.sm_carrier AS return_ship_mode,
  w_ret.w_warehouse_name AS return_warehouse,
  CASE
    WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High'
    ELSE 'Low'
  END AS revenue_category,
  SUM(ss.ss_net_paid) AS total_store_sales,
  SUM(ws.ws_net_paid) AS total_web_sales,
  SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_returns_loss,
  SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_returns_amount,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets
FROM item_tbl i
JOIN store_sales ss
  ON i.i_item_sk = ss.ss_item_sk
JOIN store_returns sr
  ON i.i_item_sk = sr.sr_item_sk
  AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN catalog_returns cr
  ON i.i_item_sk = cr.cr_item_sk
JOIN web_sales ws
  ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN customer_demographics cd_bill
  ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN customer_address ca_bill
  ON ss.ss_addr_sk = ca_bill.ca_address_sk
LEFT JOIN customer_demographics cd_ret
  ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
LEFT JOIN customer_address ca_ret
  ON sr.sr_addr_sk = ca_ret.ca_address_sk
LEFT JOIN ship_mode sm_ret
  ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
LEFT JOIN ship_mode sm_web
  ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
LEFT JOIN warehouse w_ret
  ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
LEFT JOIN warehouse w_web
  ON ws.ws_warehouse_sk = w_web.w_warehouse_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_warehouse_sk = w_ret.w_warehouse_sk
WHERE NOT EXISTS (
  SELECT 1
  FROM catalog_returns cr2
  WHERE cr2.cr_item_sk = i.i_item_sk
    AND cr2.cr_reversed_charge > 150
)
GROUP BY ROLLUP (i.i_category, ca_bill.ca_state, sm_ret.sm_carrier, w_ret.w_warehouse_name)
HAVING SUM(ss.ss_net_paid) > 0
ORDER BY total_store_sales DESC
LIMIT 100
