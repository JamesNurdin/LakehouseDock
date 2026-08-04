WITH sales_base AS (
  SELECT
    c.c_customer_id,
    SUM(cs.cs_net_paid) AS total_amount,
    COUNT(*) AS txn_count
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND sm.sm_carrier LIKE 'UPS%'
    AND c.c_customer_id IN (
      SELECT c2.c_customer_id
      FROM customer c2
      WHERE regexp_like(c2.c_login, '^admin')
    )
  GROUP BY c.c_customer_id
  HAVING SUM(cs.cs_net_paid) > (SELECT 5000)
),

sales_agg AS (
  SELECT
    c_customer_id,
    'sales' AS metric_type,
    total_amount,
    txn_count,
    substring(c_customer_id, 1, 3) AS cust_prefix,
    LAG(total_amount) OVER (PARTITION BY c_customer_id ORDER BY total_amount) AS lag_total
  FROM sales_base
),

returns_base AS (
  SELECT
    c.c_customer_id,
    SUM(sr.sr_return_amt) AS total_amount,
    COUNT(*) AS txn_count
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE regexp_like(ca.ca_city, '^San.*')
    AND sr.sr_return_amt > 0
  GROUP BY c.c_customer_id
  HAVING SUM(sr.sr_return_amt) > (SELECT 5000)
),

returns_agg AS (
  SELECT
    c_customer_id,
    'returns' AS metric_type,
    total_amount,
    txn_count,
    substring(c_customer_id, 1, 3) AS cust_prefix,
    LEAD(total_amount) OVER (PARTITION BY c_customer_id ORDER BY total_amount) AS lead_total
  FROM returns_base
)

SELECT *
FROM (
  SELECT * FROM sales_agg
  UNION DISTINCT
  SELECT * FROM returns_agg
) combined
ORDER BY total_amount DESC
LIMIT 100
