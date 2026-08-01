SELECT
  cs.cs_order_number AS order_number,
  cs.cs_sold_date_sk AS sold_date_sk,
  i.i_item_id,
  i.i_product_name,
  i.i_category,
  w_cs.w_state AS warehouse_state,
  t_cs.t_hour AS sold_hour,
  cs.cs_net_profit AS catalog_net_profit,
  ss.ss_net_profit AS store_net_profit,
  ws.ws_net_profit AS web_net_profit,
  (cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) AS total_net_profit,
  RANK() OVER (PARTITION BY i.i_category ORDER BY (cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) DESC) AS category_rank,
  CASE
    WHEN (cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) > 10000 THEN 'High'
    WHEN (cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) > 5000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_level,
  (SELECT SUM(wr_sub.wr_return_amt)
   FROM web_returns wr_sub
   WHERE wr_sub.wr_order_number = ws.ws_order_number) AS total_return_amount,
  r.r_reason_desc AS return_reason_desc
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer_demographics cd_cs ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
JOIN household_demographics hd_cs ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                 AND wr.wr_item_sk = i.i_item_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE t_cs.t_am_pm = 'PM'
  AND i.i_category = 'Electronics'
  AND hd_cs.hd_vehicle_count >= 2
  AND w_cs.w_state = 'CA'
  AND EXISTS (
    SELECT 1
    FROM web_returns wr_corr
    WHERE wr_corr.wr_order_number = ws.ws_order_number
      AND wr_corr.wr_return_amt > 50
  )
ORDER BY total_net_profit DESC, category_rank
LIMIT 100
