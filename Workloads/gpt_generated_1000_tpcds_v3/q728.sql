WITH store_daily AS (
    SELECT
        d.d_date AS sale_date,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
    GROUP BY d.d_date
),
catalog_daily AS (
    SELECT
        d.d_date AS sale_date,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
)
SELECT DISTINCT
    combined.sale_date,
    combined.channel,
    combined.net_paid,
    combined.net_profit
FROM (
    SELECT * FROM store_daily
    UNION ALL
    SELECT * FROM catalog_daily
) AS combined
WHERE combined.net_paid > (
    SELECT AVG(all_net.net_paid)
    FROM (
        SELECT net_paid FROM store_daily
        UNION ALL
        SELECT net_paid FROM catalog_daily
    ) AS all_net
)
ORDER BY combined.net_paid DESC
LIMIT 100
