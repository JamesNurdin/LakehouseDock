SELECT
  d.d_year,
  i.i_category,
  c.c_customer_id,
  SUM(ss.ss_net_paid) AS store_sales_net_paid,
  SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
  SUM(ws.ws_net_paid) AS web_sales_net_paid,
  SUM(cr.cr_return_amount) AS catalog_returns_amount,
  SUM(wr.wr_return_amt) AS web_returns_amount,
  COUNT(DISTINCT ss.ss_ticket_number) AS store_order_cnt,
  CASE
    WHEN (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) > 0 THEN 'Overall Profit'
    ELSE 'Overall Loss'
  END AS overall_profit_indicator
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  AND cs.cs_item_sk = i.i_item_sk
  AND cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  AND ws.ws_item_sk = i.i_item_sk
  AND ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_item_sk = i.i_item_sk
  AND cr.cr_refunded_customer_sk = c.c_customer_sk
  AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_item_sk = i.i_item_sk
  AND wr.wr_refunded_customer_sk = c.c_customer_sk
  AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '5001-10000'
  AND p.p_channel_tv = 'Y'
GROUP BY d.d_year, i.i_category, c.c_customer_id
ORDER BY d.d_year DESC,
         (SUM(ss.ss_net_paid) + SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid)) DESC
LIMIT 100
