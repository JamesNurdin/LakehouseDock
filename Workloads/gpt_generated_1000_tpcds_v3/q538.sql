WITH all_data AS (
  SELECT
    cp.cp_department,
    d_sold.d_date AS sold_date,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_net_profit,
    sm.sm_type,
    sm.sm_carrier,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    s.s_store_name,
    s.s_city,
    r_sr.r_reason_desc AS store_return_reason,
    r_wr.r_reason_desc AS web_return_reason,
    i.inv_quantity_on_hand,
    wp.wp_url,
    wp.wp_type,
    CASE WHEN cs.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk AND i.inv_date_sk = d_sold.d_date_sk
  LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
  LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
  LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
  LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
  LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
  LEFT JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
  LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
  LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
  WHERE d_sold.d_year = 2000
    AND cp.cp_department = 'Electronics'
    AND sm.sm_type = 'AIR'
    AND cd.cd_gender = 'M'
    AND ib.ib_lower_bound >= 50000
    AND cs.cs_quantity > 5
)
SELECT
  cp_department,
  sold_date,
  cs_item_sk,
  cs_quantity,
  cs_sales_price,
  cs_net_profit,
  profit_category,
  sm_type,
  sm_carrier,
  s_store_name,
  s_city,
  store_return_reason,
  web_return_reason,
  inv_quantity_on_hand,
  wp_url,
  wp_type,
  RANK() OVER (PARTITION BY cp_department ORDER BY cs_net_profit DESC) AS profit_rank,
  SUM(cs_net_profit) OVER (PARTITION BY cp_department ORDER BY sold_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_7day_profit
FROM all_data
ORDER BY cp_department, profit_rank
