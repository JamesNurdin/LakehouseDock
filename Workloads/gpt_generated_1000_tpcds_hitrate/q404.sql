WITH sales_agg AS (
  SELECT 
    cs.cs_bill_customer_sk AS customer_sk,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS order_count,
    MAX(cp.cp_description) AS any_description
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE regexp_like(cp.cp_description, '[0-9]{3}')
  GROUP BY cs.cs_bill_customer_sk
)
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  c.c_email_address,
  s.total_sales,
  s.total_profit,
  CASE 
    WHEN s.total_profit > 10000 THEN 'HIGH'
    WHEN s.total_profit BETWEEN 0 AND 10000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  regexp_extract(s.any_description, '([0-9]{3})', 1) AS extracted_code
FROM sales_agg s
JOIN customer c
  ON s.customer_sk = c.c_customer_sk
WHERE c.c_email_address LIKE '%@example.com'
  AND regexp_like(c.c_first_name, '^[A-Z][a-z]+$')
  AND c.c_customer_sk NOT IN (SELECT sr_customer_sk FROM store_returns)
ORDER BY s.total_sales DESC
LIMIT 100
