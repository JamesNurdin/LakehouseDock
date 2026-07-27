WITH
    returns_agg AS (
        SELECT
            cr.cr_refunded_customer_sk AS customer_sk,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns cr
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE regexp_like(cp.cp_description, '(?i)special')
        GROUP BY cr.cr_refunded_customer_sk
    ),
    sales_agg AS (
        SELECT
            ws.ws_bill_customer_sk AS customer_sk,
            SUM(ws.ws_net_paid) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit,
            ws.ws_web_site_sk AS web_site_sk
        FROM web_sales ws
        JOIN web_site wsite
            ON ws.ws_web_site_sk = wsite.web_site_sk
        WHERE wsite.web_name LIKE '%Shop%'
          AND regexp_like(wsite.web_name, '(?i)shop')
        GROUP BY ws.ws_bill_customer_sk, ws.ws_web_site_sk
    )
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    r.total_return_amount,
    r.return_cnt,
    s.total_sales,
    s.total_profit,
    w.web_name,
    w.web_city,
    SUBSTRING(w.web_name, 1, 5) AS web_name_prefix
FROM returns_agg r
JOIN sales_agg s
    ON r.customer_sk = s.customer_sk
JOIN customer c
    ON r.customer_sk = c.c_customer_sk
JOIN web_site w
    ON s.web_site_sk = w.web_site_sk
WHERE regexp_like(c.c_email_address, '@example\\.com$')
ORDER BY r.total_return_amount DESC
LIMIT 100
