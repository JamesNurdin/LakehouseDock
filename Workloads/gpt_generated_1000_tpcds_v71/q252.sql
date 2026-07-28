/*
Goal: Identify high‑value web‑sales customers whose email addresses match a specific pattern, have last names starting with "S", and have never returned a store purchase. Show their full name, email domain, the web site they bought from (only sites whose name contains "Shop"), the warehouse used, total net paid and distinct order count. Results are ordered by total spending and limited to the top 100.
*/
WITH filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
    FROM customer c
    WHERE regexp_like(c.c_email_address, '^[A-Z]+[0-9]{2}@example\\.com$')
      AND substring(c.c_last_name, 1, 1) = 'S'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
      )
),
distinct_sites AS (
    SELECT DISTINCT 
        ws.web_site_sk,
        ws.web_name
    FROM web_site ws
    WHERE ws.web_name LIKE '%Shop%'
)
SELECT
    ds.web_name,
    w.w_warehouse_id,
    concat(fc.c_first_name, ' ', fc.c_last_name) AS full_name,
    regexp_extract(fc.c_email_address, '@(.+)$') AS email_domain,
    count(DISTINCT ws.ws_order_number) AS distinct_orders,
    sum(ws.ws_net_paid) AS total_net_paid
FROM filtered_customers fc
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = fc.c_customer_sk
JOIN distinct_sites ds
    ON ws.ws_web_site_sk = ds.web_site_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_suite_number LIKE 'Suite %'
GROUP BY ds.web_name, w.w_warehouse_id, fc.c_first_name, fc.c_last_name, fc.c_email_address
ORDER BY total_net_paid DESC
LIMIT 100
