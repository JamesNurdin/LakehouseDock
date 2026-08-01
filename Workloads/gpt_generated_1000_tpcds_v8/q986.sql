WITH
    promo_filtered AS (
        SELECT
            p_promo_sk,
            p_promo_name,
            p_cost,
            p_item_sk,
            regexp_extract(p_promo_name, '(\\d+)%') AS discount_percent
        FROM promotion
        TABLESAMPLE BERNOULLI (10)
        WHERE regexp_like(p_promo_name, '(?i)discount|sale')
          AND p_channel_demo = 'N'
    ),
    unsold_items AS (
        SELECT inv_item_sk
        FROM inventory
        EXCEPT
        SELECT ws_item_sk
        FROM web_sales
    ),
    recent_customers AS (
        SELECT
            c_customer_sk,
            c_email_address,
            c_birth_year
        FROM customer
        WHERE c_birth_year >= 1950
          AND c_email_address LIKE '%@example.com'
    ),
    birth_years AS (
        SELECT DISTINCT c_birth_year
        FROM customer
        WHERE c_birth_year IS NOT NULL
        LIMIT 5
    )
SELECT
    ws_site.web_site_id,
    ws_site.web_name,
    yr.c_birth_year,
    email_parts.email_user,
    p.p_promo_name,
    p.discount_percent,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(*) AS order_cnt,
    concat(cast(ws.ws_order_number AS varchar), '-', email_parts.email_user) AS composite_key
FROM web_sales ws
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN promo_filtered p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN recent_customers rc
    ON ws.ws_bill_customer_sk = rc.c_customer_sk
CROSS JOIN LATERAL (
    SELECT
        CASE
            WHEN strpos(rc.c_email_address, '@') > 0
            THEN substr(rc.c_email_address, 1, strpos(rc.c_email_address, '@') - 1)
            ELSE rc.c_email_address
        END AS email_user
) AS email_parts
CROSS JOIN birth_years yr
WHERE ws.ws_item_sk IN (SELECT inv_item_sk FROM unsold_items)
  AND ws.ws_net_paid > (SELECT max(p_cost) FROM promotion WHERE p_channel_demo = 'N')
GROUP BY
    ws_site.web_site_id,
    ws_site.web_name,
    yr.c_birth_year,
    email_parts.email_user,
    p.p_promo_name,
    p.discount_percent,
    ws.ws_order_number
ORDER BY total_net_paid DESC
LIMIT 100
