WITH store_profit AS (
  SELECT
    p.p_promo_name AS promo_name,
    d.d_year AS year,
    SUM(ss.ss_net_profit) AS net_profit,
    'store' AS sales_channel
  FROM tpcds.store_sales ss
  JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2020
    AND p.p_channel_email = 'Y'
  GROUP BY p.p_promo_name, d.d_year
),
web_profit AS (
  SELECT
    p.p_promo_name AS promo_name,
    d.d_year AS year,
    SUM(ws.ws_net_profit) AS net_profit,
    'web' AS sales_channel
  FROM tpcds.web_sales ws
  JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN tpcds.web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE d.d_year = 2020
    AND p.p_channel_email = 'Y'
    AND w.web_county = 'Williamson County'
  GROUP BY p.p_promo_name, d.d_year
)
SELECT DISTINCT
  promo_name,
  year,
  sales_channel,
  net_profit
FROM (
  SELECT * FROM store_profit
  UNION ALL
  SELECT * FROM web_profit
) combined
ORDER BY promo_name, year, sales_channel
