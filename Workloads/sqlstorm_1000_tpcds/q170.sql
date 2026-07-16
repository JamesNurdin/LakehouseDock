WITH web_sales_enhanced AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        wp.wp_url,
        c.c_email_address,
        d.d_year,
        d.d_month_seq,
        LOWER(wp.wp_url) AS url_lc,
        REGEXP_REPLACE(wp.wp_url, '^https?://', '') AS url_without_scheme,
        REGEXP_EXTRACT(REGEXP_REPLACE(wp.wp_url, '^https?://', ''), '([^/]+)') AS url_domain,
        CASE 
            WHEN REGEXP_LIKE(wp.wp_url, '^https?://(www\\.)?') THEN 'HAS_WWW'
            ELSE 'NO_WWW'
        END AS url_www_flag,
        TRIM(BOTH '/' FROM REGEXP_EXTRACT(REGEXP_REPLACE(wp.wp_url, '^https?://[^/]+', ''), '(/.*)')) AS url_path,
        LENGTH(TRIM(BOTH '/' FROM REGEXP_EXTRACT(REGEXP_REPLACE(wp.wp_url, '^https?://[^/]+', ''), '(/.*)'))) AS url_path_len,
        LOWER(c.c_email_address) AS email_lc,
        REGEXP_EXTRACT(LOWER(c.c_email_address), '@([^@]+)$') AS email_domain,
        LENGTH(REGEXP_EXTRACT(LOWER(c.c_email_address), '@([^@]+)$')) AS email_domain_len,
        CASE 
            WHEN REGEXP_LIKE(LOWER(c.c_email_address), '@gmail\\.com$') THEN 'GMAIL'
            WHEN REGEXP_LIKE(LOWER(c.c_email_address), '@yahoo\\.com$') THEN 'YAHOO'
            ELSE 'OTHER'
        END AS email_provider
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
domain_aggregates AS (
    SELECT 
        d_year,
        d_month_seq,
        email_domain,
        url_domain,
        COUNT(*) AS sales_cnt,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(url_path_len) AS avg_path_len,
        MAX(url_path_len) AS max_path_len,
        MIN(url_path_len) AS min_path_len,
        array_join(array_agg(DISTINCT url_www_flag), ',') AS www_flags,
        CONCAT(email_domain, '-', url_domain) AS combined_domain,
        REVERSE(email_domain) AS email_domain_rev,
        email_domain_len,
        LENGTH(url_domain) AS url_domain_len,
        SUBSTR(url_domain, 1, 5) AS url_domain_prefix,
        CASE 
            WHEN url_domain LIKE '%shop%' THEN 'SHOP_IN_DOMAIN'
            ELSE 'NO_SHOP'
        END AS shop_flag,
        REGEXP_EXTRACT(url_domain, '\\.([a-z]{2,})$') AS url_tld
    FROM web_sales_enhanced
    GROUP BY d_year, d_month_seq, email_domain, url_domain, email_domain_len
    HAVING COUNT(*) > 5
)
SELECT 
    d_year,
    d_month_seq,
    email_domain,
    url_domain,
    url_tld,
    sales_cnt,
    total_sales,
    avg_path_len,
    max_path_len,
    min_path_len,
    www_flags,
    combined_domain,
    email_domain_rev,
    email_domain_len,
    url_domain_len,
    url_domain_prefix,
    shop_flag,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
FROM domain_aggregates
ORDER BY d_year, d_month_seq, sales_rank
LIMIT 200
