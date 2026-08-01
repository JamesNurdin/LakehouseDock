WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_net_profit) AS total_profit,
        'store' AS sales_channel
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
      AND d.d_date >= DATE '1998-01-01'
      AND d.d_date <= DATE '2001-12-31'
    GROUP BY d.d_year, p.p_promo_name
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_net_profit) AS total_profit,
        'web' AS sales_channel
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
      AND d.d_date >= DATE '1998-01-01'
      AND d.d_date <= DATE '2001-12-31'
    GROUP BY d.d_year, p.p_promo_name
)
SELECT year, promo_name, total_profit, sales_channel
FROM store_sales_agg
UNION ALL
SELECT year, promo_name, total_profit, sales_channel
FROM web_sales_agg
ORDER BY year, sales_channel, total_profit DESC
LIMIT 100
