WITH base AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '\\d+', 1) AS promo_number,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        wsite.web_name,
        d.d_year,
        d.d_moy,
        sm.sm_type
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
      AND wsite.web_name LIKE '%Shop%'
      AND regexp_like(sm.sm_type, 'Express')
      AND regexp_extract(p.p_promo_name, '\\d+', 1) IS NOT NULL
)
SELECT
    d_year,
    d_moy,
    sm_type,
    substring(web_name, 1, 10) AS site_prefix,
    promo_number,
    sum(ws_ext_sales_price) AS total_sales,
    sum(ws_net_profit) AS total_net_profit,
    count(*) AS order_count,
    array_agg(DISTINCT concat(c_first_name, ' ', c_last_name)) AS customer_names
FROM base
GROUP BY d_year, d_moy, sm_type, substring(web_name, 1, 10), promo_number
ORDER BY total_net_profit DESC
LIMIT 100
