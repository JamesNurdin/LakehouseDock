WITH
  store_agg AS (
    SELECT
      c.c_customer_sk,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
      c.c_email_address,
      SUM(ss.ss_net_profit) AS store_profit,
      SUM(ss.ss_quantity) AS store_quantity
    FROM
      tpcds.store_sales ss
      TABLESAMPLE BERNOULLI (10) -- sample 10 % of rows
      JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
      JOIN tpcds.date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
      AND regexp_like(c.c_email_address, '^.+@example\\.com$')
      AND c.c_last_name LIKE 'S%'
    GROUP BY
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_email_address
  ),

  web_agg AS (
    SELECT
      c.c_customer_sk,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
      c.c_email_address,
      SUM(ws.ws_net_profit) AS web_profit,
      SUM(ws.ws_quantity) AS web_quantity
    FROM
      tpcds.web_sales ws
      JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
      JOIN tpcds.date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
      AND regexp_like(c.c_email_address, '^.+@example\\.com$')
      AND c.c_last_name LIKE 'S%'
    GROUP BY
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_email_address
  )

SELECT
  COALESCE(s.c_customer_sk, w.c_customer_sk)                     AS customer_sk,
  COALESCE(s.full_name, w.full_name)                           AS full_name,
  COALESCE(s.c_email_address, w.c_email_address)               AS email_address,
  SUBSTRING(COALESCE(s.c_email_address, w.c_email_address), 1,
            POSITION('@' IN COALESCE(s.c_email_address, w.c_email_address)) - 1) AS email_user,
  regexp_extract(COALESCE(s.c_email_address, w.c_email_address), '@(.+)$', 1)          AS email_domain,
  COALESCE(s.store_profit, 0)                                   AS store_profit,
  COALESCE(w.web_profit, 0)                                     AS web_profit,
  (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0))      AS total_profit,
  COALESCE(s.store_quantity, 0)                                 AS store_quantity,
  COALESCE(w.web_quantity, 0)                                   AS web_quantity
FROM
  store_agg s
  FULL OUTER JOIN web_agg w
    ON s.c_customer_sk = w.c_customer_sk
ORDER BY
  total_profit DESC
LIMIT 100
