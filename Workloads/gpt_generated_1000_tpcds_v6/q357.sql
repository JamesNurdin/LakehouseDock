WITH joined_data AS (
  SELECT
    s.s_store_id,
    s.s_state,
    d.d_year AS sales_year,
    p.p_promo_name,
    sm.sm_type AS ship_mode_type,
    wp.wp_type AS web_page_type,
    ca_bill.ca_city AS bill_city,
    ca_ship.ca_city AS ship_city,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.ss_ext_sales_price AS store_sales_amount,
    ss.ss_net_profit AS store_profit,
    ws.ws_ext_sales_price AS web_sales_amount,
    ws.ws_net_profit AS web_profit,
    wr.wr_return_amt AS return_amount,
    CASE
      WHEN ss.ss_net_profit + ws.ws_net_profit - COALESCE(wr.wr_return_amt, 0) > 1000 THEN 'High'
      ELSE 'Medium'
    END AS profit_category
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
  JOIN customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
  JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
  JOIN income_band ib ON hd_store.hd_income_band_sk = ib.ib_income_band_sk
  -- web side joins
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_returned_date_sk = d.d_date_sk
  JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
  WHERE d.d_year = 2001
    AND d.d_moy IN (1, 2, 3)
    AND cd_store.cd_credit_rating = 'Good'
    AND ib.ib_lower_bound >= 30000
    AND p.p_channel_tv = 'Y'
    AND sm.sm_type = 'AIR'
)
SELECT
  s_store_id,
  s_state,
  sales_year,
  profit_category,
  SUM(store_sales_amount) AS total_store_sales,
  SUM(web_sales_amount) AS total_web_sales,
  SUM(store_profit + web_profit - COALESCE(return_amount, 0)) AS total_net_profit
FROM joined_data
GROUP BY s_store_id, s_state, sales_year, profit_category
HAVING SUM(store_profit + web_profit - COALESCE(return_amount, 0)) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
