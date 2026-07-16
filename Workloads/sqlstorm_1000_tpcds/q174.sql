WITH sales AS (
    SELECT d.d_year, d.d_month_seq, 'store' AS channel, ss.ss_net_paid AS net_paid, ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year, d.d_month_seq, 'web' AS channel, ws.ws_net_paid AS net_paid, ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year, d.d_month_seq, 'catalog' AS channel, cs.cs_net_paid AS net_paid, cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
)
SELECT d_year,
       d_month_seq,
       channel,
       SUM(net_paid) AS total_paid,
       SUM(net_profit) AS total_profit,
       COUNT(*) AS transaction_count,
       CASE WHEN SUM(net_paid) = 0 THEN 0 ELSE SUM(net_profit) / SUM(net_paid) END AS profit_ratio
FROM sales
GROUP BY d_year, d_month_seq, channel
ORDER BY total_paid DESC
LIMIT 20
