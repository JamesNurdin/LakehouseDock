WITH sales_agg AS (
  SELECT
    c.c_customer_id,
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    regexp_extract(c.c_email_address, '@(.*)$', 1) AS email_domain,
    d.d_year,
    SUM(ss.ss_net_profit) AS total_store_profit,
    COUNT(*) AS txn_count
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE d.d_year = 2001
    AND c.c_email_address LIKE '%@example.com'
    AND regexp_like(c.c_last_name, '^[A-M].*')
  GROUP BY
    c.c_customer_id,
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name),
    regexp_extract(c.c_email_address, '@(.*)$', 1),
    d.d_year
)

SELECT
  s.c_customer_id,
  s.full_name,
  s.email_domain,
  s.d_year,
  s.total_store_profit,
  s.txn_count,
  (
    SELECT AVG(ss2.ss_net_profit)
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = s.d_year
  ) AS avg_profit_all_customers
FROM sales_agg s
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_returning_customer_sk = s.c_customer_sk
)
ORDER BY s.total_store_profit DESC
LIMIT 100
