WITH sales_data AS (
  SELECT
    s.s_store_id,
    s.s_state,
    p.p_promo_id,
    p.p_start_date_sk,
    ca.ca_state AS ca_state,
    ca.ca_gmt_offset,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.ss_sold_date_sk,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ws.ws_ext_sales_price AS ws_ext_sales_price,
    ws.ws_net_profit AS ws_net_profit,
    (
      SELECT COALESCE(SUM(sr.sr_net_loss), 0)
      FROM store_returns sr
      WHERE sr.sr_store_sk = s.s_store_sk
        AND sr.sr_returned_date_sk = ss.ss_sold_date_sk
    ) AS store_return_loss,
    SUM(ss.ss_net_profit) OVER (
      PARTITION BY s.s_store_id
      ORDER BY ss.ss_sold_date_sk
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_store_profit
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
  LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
   AND ws.ws_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  WHERE
    s.s_state = 'CA'
    AND p.p_start_date_sk BETWEEN 2450150 AND 2450200
    AND ib.ib_upper_bound >= 50000
    AND ca.ca_gmt_offset BETWEEN -5.00 AND 0.00
    AND td.t_hour BETWEEN 9 AND 17
    AND ib.ib_lower_bound > (
      SELECT MIN(ib2.ib_lower_bound)
      FROM income_band ib2
      WHERE ib2.ib_income_band_sk = 7
    )
    AND ib.ib_upper_bound < (
      SELECT MAX(ib3.ib_upper_bound)
      FROM income_band ib3
      WHERE ib3.ib_income_band_sk = 18
    )
)
SELECT
  s_store_id,
  p_promo_id,
  ca_state,
  ib_income_band_sk,
  SUM(ss_ext_sales_price) AS total_store_sales,
  SUM(ws_ext_sales_price) AS total_web_sales,
  SUM(store_return_loss) AS total_store_returns,
  SUM(ws_net_profit) AS total_web_profit,
  MAX(running_store_profit) AS max_running_store_profit
FROM sales_data
GROUP BY ROLLUP (s_store_id, p_promo_id, ca_state, ib_income_band_sk)
ORDER BY total_store_sales DESC
LIMIT 100
