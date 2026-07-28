WITH customer_sales AS (
  SELECT
    c.c_customer_sk,
    ca.ca_state,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_cnt,
    MAX(ss.ss_sold_date_sk) AS latest_sold_date_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND ca.ca_state LIKE 'A%'
  GROUP BY c.c_customer_sk, ca.ca_state
)
SELECT
  cs.c_customer_sk,
  c.c_customer_id,
  cs.ca_state,
  regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
  CONCAT(cs.ca_state, '-', c.c_customer_id) AS state_cust_key,
  cs.total_net_profit,
  cs.transaction_cnt,
  cs.total_net_profit / cs.transaction_cnt AS avg_profit_per_txn
FROM customer_sales cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = cs.c_customer_sk
      )
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = cs.c_customer_sk
           OR wr.wr_returning_customer_sk = cs.c_customer_sk
      )
ORDER BY cs.total_net_profit DESC
LIMIT 100
