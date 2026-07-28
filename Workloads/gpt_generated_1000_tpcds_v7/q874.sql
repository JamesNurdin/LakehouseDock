WITH store_profit AS (
    SELECT
        d.d_year AS year,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year
),
web_profit AS (
    SELECT
        d.d_year AS year,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE p.p_discount_active = 'Y'
      AND wp.wp_type = 'home'
      AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year
)
SELECT year, channel, total_profit
FROM store_profit
UNION ALL
SELECT year, channel, total_profit
FROM web_profit
ORDER BY year, channel
