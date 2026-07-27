SELECT
  cc.cc_call_center_sk,
  cc.cc_name,
  cc.cc_state,
  d.d_year,
  i.i_item_id,
  i.i_brand,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_return_net_loss,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  SUM(wr.wr_return_amt) AS total_web_return_amount,
  SUM(wr.wr_net_loss) AS total_web_return_net_loss,
  RANK() OVER (PARTITION BY cc.cc_state ORDER BY (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) DESC) AS loss_rank_state
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_returned_date_sk = d.d_date_sk
 AND wr.wr_order_number = ws.ws_order_number
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND i.i_brand = 'Brand#12'
GROUP BY
  cc.cc_call_center_sk,
  cc.cc_name,
  cc.cc_state,
  d.d_year,
  i.i_item_id,
  i.i_brand
ORDER BY loss_rank_state, total_return_net_loss DESC
LIMIT 100
