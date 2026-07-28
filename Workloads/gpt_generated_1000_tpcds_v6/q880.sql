SELECT
  d.d_year,
  i_cat.i_category,
  w.w_warehouse_name,
  r.r_reason_desc,
  SUM(cr.cr_net_loss) AS catalog_net_loss,
  SUM(sr.sr_net_loss) AS store_net_loss,
  SUM(ws.ws_net_profit) AS web_profit,
  SUM(wr.wr_net_loss) AS web_return_net_loss,
  ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_net_loss) DESC) AS catalog_loss_rank,
  SUM(SUM(cr.cr_net_loss)) OVER (PARTITION BY d.d_year ORDER BY i_cat.i_category) AS running_catalog_loss
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i_cat
  ON cr.cr_item_sk = i_cat.i_item_sk
LEFT JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_address ca_ref
  ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_address ca_ret
  ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
-- store returns
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i_sr
  ON sr.sr_item_sk = i_sr.i_item_sk
LEFT JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
-- web sales
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i_ws
  ON ws.ws_item_sk = i_ws.i_item_sk
JOIN customer_demographics cd_ws_bill
  ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN customer_address ca_ws_bill
  ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
LEFT JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
LEFT JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
-- web returns
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_order_number = ws.ws_order_number
JOIN item i_wr
  ON wr.wr_item_sk = i_wr.i_item_sk
LEFT JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
GROUP BY
  d.d_year,
  i_cat.i_category,
  w.w_warehouse_name,
  r.r_reason_desc
ORDER BY catalog_net_loss DESC
LIMIT 100
