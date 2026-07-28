WITH sales AS (
  SELECT
    ca.ca_state AS state,
    'sales' AS record_type,
    SUM(ss.ss_net_paid) AS amount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
  GROUP BY ca.ca_state
  HAVING SUM(ss.ss_net_paid) > 10000
),
returns AS (
  SELECT
    ca.ca_state AS state,
    'returns' AS record_type,
    SUM(sr.sr_return_amt) AS amount
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
  GROUP BY ca.ca_state
  HAVING SUM(sr.sr_return_amt) > 10000
)
SELECT * FROM sales
UNION ALL
SELECT * FROM returns
LIMIT 100
