WITH
customer_sales AS (
  SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales,
    COUNT(*) AS sales_txn_cnt
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE c.c_birth_year BETWEEN 1950 AND 1960
    AND ss.ss_sales_price > 30
    AND ca.ca_state IN ('CA', 'NY', 'TX')
  GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state
),
customer_store_returns AS (
  SELECT
    c.c_customer_sk,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    COUNT(*) AS store_return_cnt
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE sr.sr_return_amt > 20
    AND ca.ca_state = 'CA'
    AND sr.sr_fee < 5
  GROUP BY c.c_customer_sk
),
customer_web_returns AS (
  SELECT
    c.c_customer_sk,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(*) AS web_return_cnt
  FROM web_returns wr
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE wp.wp_type = 'product'
    AND wr.wr_return_amt > 10
    AND ca.ca_state = 'CA'
  GROUP BY c.c_customer_sk
),
high_spenders AS (
  SELECT c_customer_sk
  FROM customer_sales
  WHERE total_net_paid >= 2000
),
customers_with_web_returns AS (
  SELECT c_customer_sk
  FROM customer_web_returns
  WHERE web_return_cnt > 0
),
eligible_customers AS (
  SELECT c_customer_sk
  FROM high_spenders
  EXCEPT
  SELECT c_customer_sk
  FROM customers_with_web_returns
)
SELECT
  cs.c_customer_sk,
  cs.c_first_name,
  cs.c_last_name,
  cs.ca_state,
  cs.total_net_paid,
  COALESCE(csr.total_store_return_loss, 0) AS total_store_return_loss,
  COALESCE(cwr.total_web_return_loss, 0) AS total_web_return_loss,
  (cs.total_net_paid - COALESCE(csr.total_store_return_loss, 0) - COALESCE(cwr.total_web_return_loss, 0)) AS net_profit,
  cs.sales_txn_cnt,
  COALESCE(csr.store_return_cnt, 0) AS store_return_cnt,
  COALESCE(cwr.web_return_cnt, 0) AS web_return_cnt,
  (
    SELECT AVG(inner_cs.total_net_paid - COALESCE(inner_csr.total_store_return_loss, 0) - COALESCE(inner_cwr.total_web_return_loss, 0))
    FROM customer_sales inner_cs
    LEFT JOIN customer_store_returns inner_csr ON inner_cs.c_customer_sk = inner_csr.c_customer_sk
    LEFT JOIN customer_web_returns inner_cwr ON inner_cs.c_customer_sk = inner_cwr.c_customer_sk
  ) AS avg_net_profit_all_customers
FROM eligible_customers ec
FULL OUTER JOIN customer_sales cs ON ec.c_customer_sk = cs.c_customer_sk
FULL OUTER JOIN customer_store_returns csr ON cs.c_customer_sk = csr.c_customer_sk
FULL OUTER JOIN customer_web_returns cwr ON cs.c_customer_sk = cwr.c_customer_sk
WHERE cs.c_customer_sk IS NOT NULL
  AND EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_customer_sk = cs.c_customer_sk
      AND sr2.sr_return_amt > 15
  )
ORDER BY net_profit DESC
LIMIT 100
