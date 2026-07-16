SELECT
  cp.cp_department AS department,
  sm.sm_type AS ship_type,
  w.w_state AS state,
  SUM(cs.cs_net_paid_inc_tax) AS total_sales,
  SUM(cs.cs_net_profit) AS total_profit,
  COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns_amount,
  COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
  SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_after_returns,
  RANK() OVER (ORDER BY SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) DESC) AS profit_rank
FROM
  catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
  AND cs.cs_item_sk = cr.cr_item_sk
  AND cr.cr_returned_date_sk BETWEEN 2450815 AND 2451088
WHERE
  cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
GROUP BY
  cp.cp_department,
  sm.sm_type,
  w.w_state
HAVING
  SUM(cs.cs_net_paid_inc_tax) > 5000
ORDER BY
  net_profit_after_returns DESC
LIMIT 100
