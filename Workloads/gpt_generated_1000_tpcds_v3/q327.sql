WITH store_agg AS (
    SELECT d.d_year AS year,
           'Store' AS channel,
           SUM(ss.ss_net_paid) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           CASE 
               WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High'
               WHEN SUM(ss.ss_net_profit) > 50000 THEN 'Medium'
               ELSE 'Low'
           END AS profit_tier
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_ticket_number = ss.ss_ticket_number
              AND sr.sr_net_loss > 100
          )
    GROUP BY d.d_year
),
web_agg AS (
    SELECT d.d_year AS year,
           'Web' AS channel,
           SUM(ws.ws_net_paid) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit,
           CASE 
               WHEN SUM(ws.ws_net_profit) > 120000 THEN 'High'
               WHEN SUM(ws.ws_net_profit) > 60000 THEN 'Medium'
               ELSE 'Low'
           END AS profit_tier
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND ws.ws_quantity > (
            SELECT AVG(ws2.ws_quantity)
            FROM web_sales ws2
            WHERE ws2.ws_sold_date_sk = ws.ws_sold_date_sk
          )
    GROUP BY d.d_year
)
SELECT year,
       channel,
       total_sales,
       total_profit,
       profit_tier
FROM store_agg
UNION ALL
SELECT year,
       channel,
       total_sales,
       total_profit,
       profit_tier
FROM web_agg
ORDER BY year, channel
