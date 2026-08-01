WITH web_sales_agg AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ca.ca_city,
        c.c_email_address,
        SUM(ws.ws_net_paid) AS total_web_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^.*@[^@]+\\.com$')
      AND ca.ca_city LIKE 'San%'
      AND REGEXP_LIKE(i.i_item_desc, '\\d{3}')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state, ca.ca_city, c.c_email_address
),
returns_agg AS (
    SELECT 
        c.c_customer_sk,
        SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^.*@[^@]+\\.com$')
    GROUP BY c.c_customer_sk
)
SELECT
    CONCAT(wsa.c_first_name, ' ', wsa.c_last_name) AS full_name,
    wsa.ca_state,
    SUBSTRING(wsa.ca_city, 1, 3) AS city_prefix,
    REGEXP_EXTRACT(wsa.c_email_address, '@(.+)$') AS email_domain,
    wsa.total_web_sales,
    COALESCE(ra.total_returns, 0) AS total_returns,
    wsa.total_web_sales - COALESCE(ra.total_returns, 0) AS net_total
FROM web_sales_agg wsa
LEFT JOIN returns_agg ra
    ON wsa.c_customer_sk = ra.c_customer_sk
WHERE wsa.total_web_sales > 0
ORDER BY net_total DESC
LIMIT 100
