WITH customer_domains AS (
    SELECT
        c.c_customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        regexp_extract(c.c_email_address, '@([A-Za-z0-9.-]+)$', 1) AS email_domain
    FROM tpcds.customer c
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
      AND c.c_first_name LIKE 'J%'
)
SELECT
    w.web_site_sk,
    w.web_name,
    sum(ws.ws_net_profit) AS total_net_profit,
    count(DISTINCT cd.c_customer_sk) AS distinct_example_com_customers,
    array_agg(DISTINCT cd.full_name) FILTER (WHERE cd.full_name IS NOT NULL) AS example_com_customer_names
FROM tpcds.web_sales ws
JOIN tpcds.web_site w ON ws.ws_web_site_sk = w.web_site_sk
LEFT JOIN customer_domains cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
WHERE w.web_market_manager LIKE '%James%'
  AND w.web_name LIKE '%Site%'
GROUP BY w.web_site_sk, w.web_name
ORDER BY total_net_profit DESC
LIMIT 5
