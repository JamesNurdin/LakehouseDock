WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        wp.wp_url,
        site.web_name,
        d.d_year,
        c.c_email_address
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    WHERE d.d_year = 2001
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\.(com|org|net))$')
      AND site.web_name LIKE 'Web%'
)
SELECT
    site.web_name,
    regexp_extract(wp.wp_url, '^https?://([^/]+)/', 1) AS domain,
    SUM(fws.ws_net_profit) AS total_net_profit,
    SUM(fws.ws_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt,
    CONCAT('Domain_', regexp_extract(wp.wp_url, '^https?://([^/]+)/', 1)) AS domain_tag
FROM filtered_sales fws
JOIN web_page wp ON fws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site ON fws.ws_web_site_sk = site.web_site_sk
GROUP BY
    site.web_name,
    regexp_extract(wp.wp_url, '^https?://([^/]+)/', 1)
ORDER BY total_net_profit DESC
LIMIT 100
