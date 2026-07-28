WITH
  store_data AS (
    SELECT
      d.d_year,
      s.s_store_name,
      ca.ca_country,
      SUM(ss.ss_net_paid)               AS store_sales_amount,
      SUM(ss.ss_net_profit)             AS store_profit,
      COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
      SUM(COALESCE(sr.sr_net_loss, 0))   AS store_returns_loss
    FROM store_sales ss
    JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s         ON ss.ss_store_sk   = s.s_store_sk
    JOIN customer c      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
           ON sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_item_sk      = ss.ss_item_sk
    LEFT JOIN reason r   ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'TX'
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc <> 'Customer Not Satisfied')
    GROUP BY d.d_year, s.s_store_name, ca.ca_country
  ),
  web_data AS (
    SELECT
      d.d_year,
      wp.wp_type,
      ca.ca_country,
      SUM(ws.ws_net_paid)               AS web_sales_amount,
      SUM(ws.ws_net_profit)             AS web_profit,
      COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
      SUM(COALESCE(wr.wr_net_loss, 0))  AS web_returns_loss
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp     ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr
           ON wr.wr_order_number = ws.ws_order_number
          AND wr.wr_item_sk      = ws.ws_item_sk
    LEFT JOIN reason r   ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND sm.sm_code = 'AIR'
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc <> 'Customer Not Satisfied')
    GROUP BY d.d_year, wp.wp_type, ca.ca_country
  ),
  combined AS (
    SELECT
      d_year,
      'store' AS channel,
      store_sales_amount AS sales_amount,
      store_profit       AS profit,
      distinct_customers,
      store_returns_loss AS returns_loss,
      s_store_name       AS channel_name,
      ca_country
    FROM store_data
    UNION ALL
    SELECT
      d_year,
      'web'   AS channel,
      web_sales_amount AS sales_amount,
      web_profit       AS profit,
      distinct_customers,
      web_returns_loss AS returns_loss,
      wp_type          AS channel_name,
      ca_country
    FROM web_data
  )
SELECT
  c.d_year,
  c.channel,
  c.channel_name,
  c.ca_country,
  c.sales_amount,
  c.profit,
  c.returns_loss,
  CASE WHEN c.profit > 100000 THEN 'High' ELSE 'Medium' END AS profit_category,
  COUNT(DISTINCT c.channel) OVER (PARTITION BY c.d_year) AS distinct_channels_per_year
FROM combined c
WHERE c.sales_amount > 0
  AND c.returns_loss < 5000
  AND c.ca_country IS NOT NULL
ORDER BY c.d_year DESC, c.sales_amount DESC
LIMIT 100
