WITH
store_agg AS (
  SELECT
    d.d_date AS sale_date,
    s.s_store_name AS location,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    'store' AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE d.d_year = 2001
    AND EXISTS (
      SELECT 1
      FROM catalog_returns cr
      JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      WHERE cr.cr_returned_date_sk = d.d_date_sk
        AND sm.sm_carrier = 'DHL'
    )
  GROUP BY d.d_date, s.s_store_name
),
web_agg AS (
  SELECT
    d.d_date AS sale_date,
    wp.wp_url AS location,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    'web' AS channel
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE d.d_year = 2001
    AND EXISTS (
      SELECT 1
      FROM catalog_returns cr
      JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      WHERE cr.cr_returned_date_sk = d.d_date_sk
        AND sm.sm_carrier = 'DHL'
    )
  GROUP BY d.d_date, wp.wp_url
)
SELECT sale_date, location, total_sales, total_profit, channel
FROM store_agg
UNION ALL
SELECT sale_date, location, total_sales, total_profit, channel
FROM web_agg
LIMIT 100
