WITH customer_web_max AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           max(ws.ws_net_paid) AS max_web_paid
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    s.s_store_sk,
    s.s_store_name,
    concat(s.s_city, ', ', s.s_state) AS store_location,
    sum(ss.ss_net_profit) AS total_net_profit,
    avg(ss.ss_net_profit) AS avg_net_profit,
    count(*) AS sales_transactions,
    count(DISTINCT regexp_extract(c.c_email_address, '@([^@]*)[.]com$', 1)) AS distinct_email_domains,
    length(s.s_market_desc) AS market_desc_len,
    max(cwm.max_web_paid) AS max_customer_web_paid
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_web_max cwm ON c.c_customer_sk = cwm.cust_sk
WHERE d.d_year = 2001
  AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@[^@]+[.]com$')
  AND s.s_market_desc LIKE '%modern%'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_store_sk = s.s_store_sk
          AND sr.sr_return_quantity > 0
    )
GROUP BY
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc
ORDER BY total_net_profit DESC
LIMIT 100
