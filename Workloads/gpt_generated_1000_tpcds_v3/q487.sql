WITH catalog_customer_sales AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        SUM(cs.cs_net_paid) AS total_paid,
        COUNT(*) AS order_cnt,
        MIN(d.d_year) AS first_year,
        MAX(d.d_year) AS last_year
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)discount|sale')
      AND cp.cp_type LIKE 'C_%'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
),
web_customer_sales AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        SUM(ws.ws_net_paid) AS total_paid,
        COUNT(*) AS order_cnt,
        MIN(d.d_year) AS first_year,
        MAX(d.d_year) AS last_year
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '^Holiday')
      AND p.p_channel_tv = 'Y'
      AND p.p_promo_id LIKE 'PROMO_%'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
)
SELECT
    ccs.c_customer_sk,
    ccs.full_name,
    ccs.email_domain,
    ccs.total_paid,
    ccs.order_cnt,
    ccs.first_year,
    ccs.last_year,
    'Catalog' AS sales_source
FROM catalog_customer_sales ccs
UNION ALL
SELECT
    wcs.c_customer_sk,
    wcs.full_name,
    wcs.email_domain,
    wcs.total_paid,
    wcs.order_cnt,
    wcs.first_year,
    wcs.last_year,
    'Web' AS sales_source
FROM web_customer_sales wcs
ORDER BY total_paid DESC
LIMIT 100
