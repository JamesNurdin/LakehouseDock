WITH sales_agg AS (
  SELECT
    c.c_customer_sk,
    ca.ca_state,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  GROUP BY c.c_customer_sk, ca.ca_state
  HAVING SUM(cs.cs_net_paid) > 1000
),

sales_customers AS (
  SELECT cs.cs_bill_customer_sk AS c_customer_sk
  FROM catalog_sales cs
  GROUP BY cs.cs_bill_customer_sk
),

store_return_customers AS (
  SELECT sr.sr_customer_sk AS c_customer_sk
  FROM store_returns sr
  GROUP BY sr.sr_customer_sk
),

no_store_return_customers AS (
  SELECT c_customer_sk FROM sales_customers
  EXCEPT
  SELECT c_customer_sk FROM store_return_customers
),

ranked AS (
  SELECT
    s.c_customer_sk,
    s.ca_state,
    s.total_net_paid,
    s.sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY s.ca_state ORDER BY s.total_net_paid DESC) AS rn
  FROM sales_agg s
  JOIN no_store_return_customers n ON s.c_customer_sk = n.c_customer_sk
)
SELECT
  rn,
  c_customer_sk,
  ca_state,
  total_net_paid,
  sales_cnt
FROM ranked
WHERE rn <= 5
ORDER BY ca_state, rn
LIMIT 100
