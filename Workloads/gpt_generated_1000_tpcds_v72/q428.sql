WITH sales_agg AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND i.i_brand_id = 10
    AND cd.cd_gender = 'F'
    AND hd.hd_income_band_sk = 5
    AND ca.ca_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY i.i_item_id, i.i_product_name, d.d_year
)

SELECT
  sa.i_item_id,
  sa.i_product_name,
  sa.d_year,
  sa.total_sales,
  sa.total_profit,
  sa.total_return_amount,
  RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_profit DESC) AS profit_rank,
  CASE WHEN EXISTS (
        SELECT 1
        FROM call_center cc
        JOIN date_dim d_cc ON cc.cc_open_date_sk = d_cc.d_date_sk
        WHERE d_cc.d_year = sa.d_year
          AND cc.cc_state = 'CA'
      ) THEN 'Has Call Center' ELSE 'No Call Center' END AS call_center_flag,
  cp.cp_type AS catalog_type
FROM sales_agg sa
JOIN item i ON sa.i_item_id = i.i_item_id
JOIN date_dim d2 ON d2.d_year = sa.d_year
JOIN catalog_page cp ON cp.cp_start_date_sk = d2.d_date_sk
WHERE EXISTS (
        SELECT 1
        FROM web_sales ws
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        WHERE ws.ws_item_sk = i.i_item_sk
          AND d_ws.d_year = sa.d_year
          AND sm.sm_type = 'AIR'
          AND w.w_state = 'CA'
          AND wp.wp_type = 'HOME'
          AND we.web_market_manager = 'John Doe'
      )
ORDER BY sa.d_year, profit_rank
LIMIT 100
