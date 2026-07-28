WITH store_profit AS (
    SELECT
        d.d_year AS year,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS overall_avg_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_purpose = 'Unknown'
      AND EXISTS (
            SELECT 1
            FROM catalog_sales cs
            WHERE cs.cs_promo_sk = p.p_promo_sk
              AND cs.cs_net_paid > 0
        )
    GROUP BY d.d_year
),
web_profit AS (
    SELECT
        d.d_year AS year,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2) AS overall_avg_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_purpose = 'Unknown'
      AND EXISTS (
            SELECT 1
            FROM catalog_sales cs
            WHERE cs.cs_promo_sk = p.p_promo_sk
              AND cs.cs_net_paid > 0
        )
    GROUP BY d.d_year
)
SELECT year, channel, total_net_paid, overall_avg_net_paid
FROM store_profit
UNION ALL
SELECT year, channel, total_net_paid, overall_avg_net_paid
FROM web_profit
ORDER BY year, channel
LIMIT 100
