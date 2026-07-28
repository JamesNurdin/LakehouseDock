WITH relevant_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2020 AND 2022
)
SELECT year,
       channel,
       total_net_paid
FROM (
    SELECT d.d_year AS year,
           'catalog' AS channel,
           SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN relevant_dates d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY d.d_year
    UNION ALL
    SELECT d.d_year AS year,
           'web' AS channel,
           SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN relevant_dates d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY d.d_year
) AS unified_sales
ORDER BY year,
         total_net_paid DESC
LIMIT 100
