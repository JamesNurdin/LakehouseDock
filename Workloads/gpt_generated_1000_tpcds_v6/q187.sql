WITH
  store_agg AS (
    SELECT
      d.d_year,
      'store' AS channel,
      SUM(ss.ss_net_profit) AS total_profit,
      COALESCE(SUM(sr.sr_net_loss), 0) AS total_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
      AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND c.c_birth_year BETWEEN 1970 AND 1980
      AND hd.hd_vehicle_count > 1
      AND ib.ib_lower_bound >= 50000
      AND r.r_reason_desc <> 'Damaged'
    GROUP BY d.d_year
  ),

  catalog_agg AS (
    SELECT
      d.d_year,
      'catalog' AS channel,
      SUM(cs.cs_net_profit) AS total_profit,
      0.0 AS total_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Electronics'
      AND ib.ib_upper_bound <= 150000
    GROUP BY d.d_year
  ),

  web_agg AS (
    SELECT
      d.d_year,
      'web' AS channel,
      SUM(ws.ws_net_profit) AS total_profit,
      COALESCE(SUM(wr.wr_net_loss), 0) AS total_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
      AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND we.web_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND ib.ib_lower_bound >= 50000
      AND r.r_reason_desc IS NULL
    GROUP BY d.d_year
  ),

  combined_sales AS (
    SELECT d_year, channel, total_profit - total_loss AS net_amount
    FROM store_agg
    UNION ALL
    SELECT d_year, channel, total_profit - total_loss AS net_amount
    FROM catalog_agg
  ),

  final_union AS (
    SELECT * FROM combined_sales
    UNION ALL
    SELECT d_year, channel, total_profit - total_loss AS net_amount
    FROM web_agg
  )
SELECT
  d_year,
  SUM(net_amount) AS year_net_profit
FROM final_union
GROUP BY d_year
HAVING SUM(net_amount) > 1000000
ORDER BY year_net_profit DESC
LIMIT 100
