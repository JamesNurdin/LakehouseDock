WITH store_sales_monthly AS (
    SELECT
        date_trunc('month', d.d_date) AS month_start,
        p.p_promo_name AS promo_name,
        s.s_store_name AS store_name,
        sum(ss.ss_net_paid) AS total_net_paid,
        sum(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY
        date_trunc('month', d.d_date),
        p.p_promo_name,
        s.s_store_name
),
web_sales_monthly AS (
    SELECT
        date_trunc('month', d.d_date) AS month_start,
        p.p_promo_name AS promo_name,
        w.web_name AS website_name,
        sum(ws.ws_net_paid) AS total_net_paid,
        sum(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY
        date_trunc('month', d.d_date),
        p.p_promo_name,
        w.web_name
)
SELECT
    month_start,
    promo_name,
    'store' AS sales_channel,
    store_name AS entity_name,
    total_net_paid,
    total_net_profit
FROM store_sales_monthly
UNION ALL
SELECT
    month_start,
    promo_name,
    'web' AS sales_channel,
    website_name AS entity_name,
    total_net_paid,
    total_net_profit
FROM web_sales_monthly
ORDER BY month_start, promo_name, sales_channel
