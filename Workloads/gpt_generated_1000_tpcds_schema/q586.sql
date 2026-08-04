WITH
  ws_agg AS (
    SELECT
      ws_bill_customer_sk AS cust_sk,
      SUM(ws_net_profit) AS total_profit,
      COUNT(*) AS order_cnt
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_wholesale_cost > 20
      AND ws_list_price < 150
      AND ws_sales_price BETWEEN 10 AND 100
    GROUP BY ws_bill_customer_sk
  ),
  sr_agg AS (
    SELECT
      sr_customer_sk AS cust_sk,
      SUM(sr_return_amt_inc_tax) AS total_return,
      COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_amt_inc_tax > 0
      AND sr_reason_sk IN (7, 24, 29)
      AND sr_refunded_cash < 2000
    GROUP BY sr_customer_sk
  ),
  filtered_customers AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_birth_country,
      c.c_salutation,
      cd.cd_gender,
      cd.cd_marital_status,
      cd.cd_dep_count,
      split(c.c_salutation, ' ') AS salutation_parts,
      c.c_current_cdemo_sk
    FROM customer c
    JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_country IN ('CHILE', 'JORDAN', 'TOGO')
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_count >= 1
  ),
  customer_with_returns AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_amt_inc_tax > 500
  )
SELECT
  fc.c_customer_sk,
  fc.c_first_name,
  fc.c_last_name,
  fc.c_birth_country,
  fc.c_salutation,
  cd.cd_gender,
  COALESCE(ws.total_profit, 0) AS total_profit,
  COALESCE(sr.total_return, 0) AS total_return,
  CASE
    WHEN COALESCE(ws.total_profit, 0) > 1000 THEN 'HIGH'
    WHEN COALESCE(ws.total_profit, 0) > 0 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  ROW_NUMBER() OVER (PARTITION BY fc.c_birth_country ORDER BY COALESCE(ws.total_profit, 0) DESC) AS rank_in_country,
  sal_part
FROM filtered_customers fc
JOIN customer_demographics cd
  ON fc.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN ws_agg ws
  ON fc.c_customer_sk = ws.cust_sk
LEFT JOIN sr_agg sr
  ON fc.c_customer_sk = sr.cust_sk
CROSS JOIN UNNEST(fc.salutation_parts) AS t(sal_part)
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = fc.c_customer_sk
          AND sr2.sr_reason_sk = 3
      )
EXCEPT
SELECT
  c.c_customer_sk,
  c.c_first_name,
  c.c_last_name,
  c.c_birth_country,
  c.c_salutation,
  cd.cd_gender,
  0 AS total_profit,
  0 AS total_return,
  'LOW' AS profit_category,
  0 AS rank_in_country,
  NULL AS sal_part
FROM customer c
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE c.c_birth_country = 'CHILE'
  AND cd.cd_marital_status = 'M'
  AND cd.cd_dep_count = 0
ORDER BY total_profit DESC
LIMIT 100
