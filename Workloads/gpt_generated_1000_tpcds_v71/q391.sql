WITH
  store_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq AS month_seq,
      'store' AS channel,
      SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq
  ),
  web_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq AS month_seq,
      'web' AS channel,
      SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq
  )
SELECT d_year,
       month_seq,
       channel,
       total_net_profit
FROM store_agg
UNION ALL
SELECT d_year,
       month_seq,
       channel,
       total_net_profit
FROM web_agg
ORDER BY d_year,
         month_seq,
         channel
LIMIT 100
