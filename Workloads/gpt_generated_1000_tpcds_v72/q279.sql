WITH promo_periods AS (
    SELECT p.p_promo_sk
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
avg_store_profit AS (
    SELECT AVG(ss.ss_net_profit) AS avg_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_sk IN (SELECT p_promo_sk FROM promo_periods)
)
SELECT
    ss.ss_item_sk AS item_sk,
    d.d_month_seq AS month_seq,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_net_profit) / (SELECT avg_profit FROM avg_store_profit) AS profit_vs_avg,
    CAST('store' AS varchar) AS channel
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_promo_sk IN (SELECT p_promo_sk FROM promo_periods)
  AND ss.ss_net_profit > 0
GROUP BY ss.ss_item_sk, d.d_month_seq

UNION ALL

SELECT
    ws.ws_item_sk AS item_sk,
    d.d_month_seq AS month_seq,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_net_profit) / (SELECT avg_profit FROM avg_store_profit) AS profit_vs_avg,
    CAST('web' AS varchar) AS channel
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE p.p_promo_sk IN (SELECT p_promo_sk FROM promo_periods)
  AND ws.ws_net_profit > 0
GROUP BY ws.ws_item_sk, d.d_month_seq

ORDER BY total_profit DESC
LIMIT 100
