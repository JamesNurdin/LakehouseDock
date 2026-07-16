WITH processed AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_net_paid,
        ws.ws_web_site_sk,
        w.web_site_id,
        w.web_name,
        LOWER(REGEXP_EXTRACT(wp.wp_url, '^https?://([^/]+)/?', 1)) AS website_domain,
        LOWER(REGEXP_REPLACE(wp.wp_url, '^https?://', '')) AS normalized_url,
        c.c_customer_sk,
        LOWER(c.c_email_address) AS email_norm,
        REGEXP_EXTRACT(c.c_email_address, '@([^\\.]+\\..+)', 1) AS email_domain,
        TRIM(CONCAT_WS(' ', c.c_first_name, c.c_last_name)) AS full_name,
        SUBSTRING(TRIM(CONCAT_WS(' ', c.c_first_name, c.c_last_name)), 1, 20) AS name_trim,
        CONCAT(
            TRIM(CONCAT_WS('_',
                SUBSTRING(TRIM(CONCAT_WS(' ', c.c_first_name, c.c_last_name)), 1, 20),
                COALESCE(REGEXP_EXTRACT(c.c_email_address, '@([^\\.]+\\..+)', 1), 'unknown')
            )),
            '_',
            CAST(c.c_customer_sk AS VARCHAR)
        ) AS customer_fingerprint,
        cp.cp_description,
        REGEXP_REPLACE(cp.cp_description, '[^A-Za-z0-9 ]', ' ') AS description_alpha,
        REGEXP_REPLACE(cp.cp_description, '\\s+', ' ') AS description_normalized
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    LEFT JOIN
        catalog_page cp ON wp.wp_web_page_id = cp.cp_catalog_page_id
)
SELECT
    p.web_site_id,
    p.web_name,
    p.website_domain,
    p.normalized_url,
    d.d_year,
    COUNT(*) AS total_visits,
    SUM(p.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT p.c_customer_sk) AS unique_customers,
    COUNT(DISTINCT p.email_domain) AS unique_email_domains,
    MIN(p.customer_fingerprint) AS sample_fingerprint,
    AVG(LENGTH(p.description_alpha)) AS avg_alpha_desc_len,
    CONCAT('Site_', p.web_site_id, '_', CAST(d.d_year AS VARCHAR)) AS composite_key
FROM
    processed p
JOIN
    date_dim d ON p.ws_sold_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2000 AND 2002
GROUP BY
    p.web_site_id,
    p.web_name,
    p.website_domain,
    p.normalized_url,
    d.d_year
ORDER BY
    total_net_paid DESC
LIMIT 10
