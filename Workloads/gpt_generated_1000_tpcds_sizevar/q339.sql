WITH customer_perf AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ib.ib_upper_bound,
    hd.hd_vehicle_count,
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    td.t_hour,
    i.i_item_id,
    i.i_current_price,
    sm.sm_type,
    wp.wp_autogen_flag,
    wsite.web_state,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    SUM(ws.ws_net_profit) OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_order_number ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS profit_last_7_orders
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE ib.ib_upper_bound >= 100000
    AND hd.hd_vehicle_count >= 2
    AND i.i_current_price BETWEEN 50 AND 500
    AND sm.sm_code = 'SM01'
    AND td.t_hour BETWEEN 8 AND 18
    AND wp.wp_autogen_flag = 'N'
    AND wsite.web_state = 'CA'
    AND c.c_birth_year BETWEEN 1950 AND 1990
)
SELECT
  cp.c_customer_id,
  cp.c_first_name,
  cp.c_last_name,
  cp.ib_upper_bound,
  cp.hd_vehicle_count,
  cp.ws_order_number,
  cp.ws_ext_sales_price,
  cp.ws_net_profit,
  cp.profit_rank,
  cp.profit_last_7_orders,
  CASE
    WHEN cp.ws_net_profit > (
      SELECT AVG(ws2.ws_net_profit)
      FROM web_sales ws2
      JOIN household_demographics hd2 ON ws2.ws_bill_hdemo_sk = hd2.hd_demo_sk
      JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
      WHERE ib2.ib_upper_bound >= 100000
    ) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS profit_vs_avg
FROM customer_perf cp
WHERE cp.profit_rank <= 5
ORDER BY cp.ws_net_profit DESC
LIMIT 100
