WITH base AS (
  SELECT
    c.c_customer_id,
    t.t_sub_shift,
    i.i_category,
    SUM(cs.cs_net_profit - cr.cr_net_loss + ss.ss_net_profit - sr.sr_net_loss + ws.ws_net_profit - wr.wr_net_loss) AS total_net_profit
  FROM catalog_sales cs
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_time_sk = t.t_time_sk
  JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_return_time_sk = t.t_time_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_order_number = ws.ws_order_number
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  -- Additional dimension joins to satisfy join rules
  JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
  JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  JOIN customer c_ss
    ON ss.ss_customer_sk = c_ss.c_customer_sk
  JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
  JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
  JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
  JOIN customer_demographics cd_ws
    ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
  JOIN household_demographics hd_ws
    ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
  JOIN customer c_ws
    ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
  JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
  JOIN customer_demographics cd_wr
    ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
  JOIN household_demographics hd_wr
    ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
  JOIN customer c_wr
    ON wr.wr_refunded_customer_sk = c_wr.c_customer_sk
  WHERE t.t_sub_shift = 'morning'
    AND i.i_category = 'Electronics'
    AND c.c_preferred_cust_flag = 'Y'
    AND w.w_city = 'Madison'
    AND inv.inv_quantity_on_hand > 10
    AND cd.cd_credit_rating = 'Good'
  GROUP BY c.c_customer_id, t.t_sub_shift, i.i_category
)
SELECT
  c_customer_id,
  t_sub_shift,
  i_category,
  total_net_profit,
  ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM base
ORDER BY total_net_profit DESC
LIMIT 100
