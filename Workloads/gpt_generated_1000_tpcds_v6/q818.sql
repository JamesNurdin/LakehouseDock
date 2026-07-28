WITH promo_sales AS (
    SELECT
        CONCAT('Promo_', COALESCE(regexp_extract(p.p_promo_id, '\\d+', 0), ''), '_', SUBSTRING(p.p_promo_name, 1, 10)) AS category,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND regexp_like(p.p_promo_name, '(?i)discount')
      AND p.p_channel_email = 'Y'
    GROUP BY CONCAT('Promo_', COALESCE(regexp_extract(p.p_promo_id, '\\d+', 0), ''), '_', SUBSTRING(p.p_promo_name, 1, 10))
),
site_sales AS (
    SELECT
        CONCAT('Site_', SUBSTRING(wsite.web_name, 1, 5)) AS category,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND wsite.web_name LIKE '%Shop%'
      AND regexp_like(wsite.web_name, '(?i)online')
    GROUP BY CONCAT('Site_', SUBSTRING(wsite.web_name, 1, 5))
)
SELECT category, total_profit
FROM promo_sales
UNION ALL
SELECT category, total_profit
FROM site_sales
ORDER BY total_profit DESC
LIMIT 10
