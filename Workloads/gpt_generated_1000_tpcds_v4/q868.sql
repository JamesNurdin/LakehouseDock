WITH joined_data AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    sm.sm_carrier,
    we.web_country,
    cp.cp_department,
    s.s_state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ws.ws_net_profit,
    ss.ss_net_profit AS store_net_profit,
    wr.wr_net_loss,
    ws.ws_quantity,
    ss.ss_quantity AS store_quantity,
    ws.ws_order_number,
    ss.ss_ticket_number
  FROM
    web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
      AND ss.ss_item_sk = i.i_item_sk
      AND ss.ss_store_sk = s.s_store_sk
)
SELECT
  d_year,
  i_category,
  sm_carrier,
  web_country,
  SUM(ws_net_profit) AS total_web_profit,
  SUM(COALESCE(store_net_profit, 0)) AS total_store_profit,
  SUM(COALESCE(wr_net_loss, 0)) AS total_return_loss,
  COUNT(DISTINCT ws_order_number) AS web_orders,
  COUNT(DISTINCT ss_ticket_number) AS store_tickets
FROM joined_data
WHERE
  d_year BETWEEN 1999 AND 2001
  AND i_category = 'Electronics'
  AND sm_carrier = 'UPS'
  AND web_country = 'United States'
  AND s_state = 'CA'
GROUP BY
  d_year,
  i_category,
  sm_carrier,
  web_country
ORDER BY
  total_web_profit DESC
LIMIT 100
