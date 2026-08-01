WITH
  /* customers with at least one catalog purchase (sampled) in 2022 */
  catalog_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      SUM(cs.cs_ext_sales_price) AS catalog_spent,
      MIN(d.d_date) AS first_purchase_date
    FROM catalog_sales cs
      TABLESAMPLE BERNOULLI (10)  -- sample 10% of rows
      JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
      JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
  ),

  /* customers with at least one web purchase in 2022 */
  web_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      SUM(ws.ws_ext_sales_price) AS web_spent,
      MIN(d.d_date) AS first_purchase_date
    FROM web_sales ws
      JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
      JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
  ),

  /* distinct set of customers who bought either via catalog or web */
  purchase_keys AS (
    SELECT c_customer_sk FROM catalog_agg
    UNION
    SELECT c_customer_sk FROM web_agg
  ),

  /* customers who have at least one store return in 2022 */
  return_keys AS (
    SELECT DISTINCT sr.sr_customer_sk AS c_customer_sk
    FROM store_returns sr
      JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  ),

  /* customers who purchased but never returned (EXCEPT) */
  eligible_customers AS (
    SELECT pk.c_customer_sk
    FROM purchase_keys pk
    EXCEPT
    SELECT rk.c_customer_sk FROM return_keys rk
  ),

  /* combine catalog and web aggregates for the eligible customers */
  customer_agg AS (
    SELECT
      e.c_customer_sk,
      COALESCE(cat.c_first_name, web.c_first_name) AS c_first_name,
      COALESCE(cat.c_last_name, web.c_last_name) AS c_last_name,
      COALESCE(cat.catalog_spent, 0) + COALESCE(web.web_spent, 0) AS total_spent,
      LEAST(
        COALESCE(cat.first_purchase_date, DATE '9999-12-31'),
        COALESCE(web.first_purchase_date, DATE '9999-12-31')
      ) AS first_purchase_date
    FROM eligible_customers e
      LEFT JOIN catalog_agg cat ON e.c_customer_sk = cat.c_customer_sk
      LEFT JOIN web_agg web ON e.c_customer_sk = web.c_customer_sk
  )
SELECT
  ca.c_customer_sk,
  ca.c_first_name,
  ca.c_last_name,
  ca.total_spent,
  ca.first_purchase_date,
  (
    SELECT COUNT(*)
    FROM store_returns sr
    WHERE sr.sr_customer_sk = ca.c_customer_sk
  ) AS total_returns
FROM customer_agg ca
ORDER BY ca.total_spent DESC
OFFSET 0 ROWS
LIMIT 100
