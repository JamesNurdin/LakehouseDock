WITH sales_by_site AS (
    SELECT 
        site.web_site_id,
        site.web_name,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1) AS promo_code_extracted,
        CASE WHEN REGEXP_LIKE(c.c_email_address, '@gmail\\.com$') THEN 'Gmail' ELSE 'Other' END AS email_provider,
        CASE WHEN ca.ca_street_type LIKE 'St%' THEN 'Street' ELSE ca.ca_street_type END AS street_type_class,
        init.initials AS customer_initials
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT substring(c.c_first_name, 1, 1) || substring(c.c_last_name, 1, 1) AS initials
    ) AS init
    WHERE d.d_year = 2001
      AND ca.ca_street_type LIKE 'St%'
      AND REGEXP_LIKE(c.c_email_address, '@gmail\\.com$')
    GROUP BY 
        site.web_site_id,
        site.web_name,
        d.d_year,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1),
        CASE WHEN REGEXP_LIKE(c.c_email_address, '@gmail\\.com$') THEN 'Gmail' ELSE 'Other' END,
        CASE WHEN ca.ca_street_type LIKE 'St%' THEN 'Street' ELSE ca.ca_street_type END,
        init.initials
)
SELECT 
    web_site_id,
    web_name,
    d_year,
    total_sales,
    total_profit,
    order_count,
    promo_code_extracted,
    email_provider,
    street_type_class,
    customer_initials,
    ROW_NUMBER() OVER (PARTITION BY web_name ORDER BY total_sales DESC) AS rn
FROM sales_by_site
ORDER BY total_sales DESC
LIMIT 100
