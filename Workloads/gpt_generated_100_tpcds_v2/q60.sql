WITH daily_profit AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
    GROUP BY cs.cs_sold_date_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    AVG(dp.total_net_profit) AS avg_daily_profit
FROM daily_profit dp
JOIN date_dim d ON dp.date_sk = d.d_date_sk
WHERE d.d_year = 2000
GROUP BY d.d_year, d.d_month_seq
HAVING AVG(dp.total_net_profit) > 10000
ORDER BY d.d_year, d.d_month_seq
