WITH web_promo AS (
   SELECT
      TRIM(t.channel) AS category,
      SUM(ws.ws_net_profit) AS total_amount,
      'web' AS source
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
   CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel)
   WHERE d.d_year = 2002
   GROUP BY TRIM(t.channel)
),
store_ret AS (
   SELECT
      r.r_reason_desc AS category,
      SUM(sr.sr_net_loss) AS total_amount,
      'store' AS source
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
   GROUP BY r.r_reason_desc
)
SELECT category, total_amount, source
FROM web_promo
UNION ALL
SELECT category, total_amount, source
FROM store_ret
ORDER BY total_amount DESC
LIMIT 100
