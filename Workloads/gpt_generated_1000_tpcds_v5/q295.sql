WITH filtered_customers AS (
    SELECT c_customer_sk,
           c_last_name,
           c_email_address
    FROM tpcds.customer
    WHERE c_last_name LIKE 'S%'
      AND regexp_like(c_email_address, '@example\\.com$')
),
filtered_call_centers AS (
    SELECT cc_call_center_sk,
           cc_name,
           cc_city,
           cc_zip,
           cc_mkt_desc,
           concat(cc_name, ' - ', cc_city) AS cc_label
    FROM tpcds.call_center
    WHERE cc_zip LIKE '3%'
      AND regexp_like(cc_mkt_desc, '\\bReduced\\b')
)
SELECT 
    fcc.cc_label,
    fcc.cc_city,
    MIN(regexp_extract(fc.c_email_address, '@(.*)$', 1)) AS email_domain,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_count
FROM tpcds.catalog_sales cs
JOIN filtered_customers fc ON cs.cs_bill_customer_sk = fc.c_customer_sk
JOIN filtered_call_centers fcc ON cs.cs_call_center_sk = fcc.cc_call_center_sk
GROUP BY fcc.cc_label, fcc.cc_city
ORDER BY total_net_profit DESC
LIMIT 10
