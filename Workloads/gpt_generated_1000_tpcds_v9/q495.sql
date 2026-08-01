WITH
  store_sales_base AS (
    SELECT
      'Store' AS sales_channel,
      d.d_year AS year,
      i.i_category AS category,
      i.i_brand AS brand,
      s.s_store_name AS location_name,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid AS net_paid,
      ss.ss_net_profit AS net_profit,
      COALESCE(sr.sr_return_amt, 0) AS return_amount,
      s.s_store_sk AS location_key,
      cs.cc_market_manager AS market_manager
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN call_center cs ON cs.cc_closed_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND s.s_state = 'CA'
      AND cs.cc_market_manager = 'HENRY'
      AND r.r_reason_desc LIKE '%damaged%'
  ),
  web_sales_base AS (
    SELECT
      'Web' AS sales_channel,
      d.d_year AS year,
      i.i_category AS category,
      i.i_brand AS brand,
      ws_site.web_name AS location_name,
      ws.ws_quantity AS quantity,
      ws.ws_net_paid AS net_paid,
      ws.ws_net_profit AS net_profit,
      COALESCE(wr.wr_return_amt, 0) AS return_amount,
      ws.ws_web_site_sk AS location_key,
      sm.sm_carrier AS ship_carrier
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ws_site.web_state = 'CA'
      AND p.p_promo_name LIKE '%Clearance%'
      AND sm.sm_carrier = 'MSC'
      AND r.r_reason_desc LIKE '%damaged%'
  ),
  union_sales AS (
    SELECT
      sales_channel,
      year,
      category,
      brand,
      location_name,
      location_key,
      quantity,
      net_paid,
      net_profit,
      return_amount
    FROM store_sales_base
    UNION ALL
    SELECT
      sales_channel,
      year,
      category,
      brand,
      location_name,
      location_key,
      quantity,
      net_paid,
      net_profit,
      return_amount
    FROM web_sales_base
  )
SELECT
  sales_channel,
  year,
  category,
  brand,
  location_name,
  SUM(quantity) AS total_quantity,
  SUM(net_paid) AS total_net_paid,
  SUM(net_profit) AS total_net_profit,
  SUM(return_amount) AS total_return_amount,
  CASE
    WHEN sales_channel = 'Store' THEN (
      SELECT COALESCE(SUM(sr.sr_return_amt), 0)
      FROM store_returns sr
      JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
      WHERE s2.s_store_name = location_name
    )
    ELSE NULL
  END AS store_total_return_amount
FROM union_sales
GROUP BY CUBE (sales_channel, year, category, brand, location_name)
HAVING SUM(net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
