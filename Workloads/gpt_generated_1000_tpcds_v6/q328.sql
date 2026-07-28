SELECT
    i.i_item_id,
    i.i_product_name,
    cc.cc_name AS call_center_name,
    sm.sm_ship_mode_id,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
    (SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) - SUM(COALESCE(sr.sr_net_loss, 0))) AS net_profit_after_returns,
    ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY (SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) - SUM(COALESCE(sr.sr_net_loss, 0))) DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN store_returns sr
  ON i.i_item_sk = sr.sr_item_sk
LEFT JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_class_id IN (1, 2)
  AND sm.sm_code = 'AIR'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    cc.cc_name,
    sm.sm_ship_mode_id,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name
ORDER BY net_profit_after_returns DESC
LIMIT 100
