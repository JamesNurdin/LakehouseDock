WITH distinct_promotions AS (
    SELECT DISTINCT p.p_promo_sk,
                    p.p_promo_id,
                    p.p_promo_name
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '[A-Z]{3}[0-9]{2}')
),
promo_sales AS (
    SELECT
        'Promotion' AS source_type,
        dp.p_promo_id AS source_id,
        dp.p_promo_name AS source_name,
        regexp_extract(dp.p_promo_name, '(\\d+)', 1) AS extracted_code,
        SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN distinct_promotions dp ON ss.ss_promo_sk = dp.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
    GROUP BY dp.p_promo_id,
             dp.p_promo_name,
             regexp_extract(dp.p_promo_name, '(\\d+)', 1)
),
distinct_web_sites AS (
    SELECT DISTINCT w.web_site_sk,
                    w.web_site_id,
                    w.web_name,
                    w.web_mkt_desc
    FROM web_site w
    WHERE w.web_name LIKE 'A%'
      AND regexp_like(w.web_mkt_desc, 'Electric')
),
web_sales_agg AS (
    SELECT
        'WebSite' AS source_type,
        w.web_site_id AS source_id,
        w.web_name AS source_name,
        regexp_extract(w.web_mkt_desc, '(\\w+)', 1) AS extracted_code,
        SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN distinct_web_sites w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY w.web_site_id,
             w.web_name,
             regexp_extract(w.web_mkt_desc, '(\\w+)', 1)
)
SELECT
    source_type,
    source_id,
    source_name,
    extracted_code,
    total_sales,
    CONCAT(source_type, '_', source_id) AS source_key
FROM (
    SELECT * FROM promo_sales
    UNION
    SELECT * FROM web_sales_agg
) AS combined
ORDER BY total_sales DESC
LIMIT 100
