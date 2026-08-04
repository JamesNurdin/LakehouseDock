WITH cust_profit AS (
  SELECT
    c.c_customer_id,
    ca.ca_city,
    CONCAT(c.c_customer_id, '-', ca.ca_city) AS cust_key,
    MIN(regexp_extract(cp.cp_description, '(\\d{3})')) AS code,
    SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE regexp_like(cp.cp_description, '\\d{3}')
    AND ca.ca_city LIKE 'A%'
  GROUP BY c.c_customer_id, ca.ca_city, CONCAT(c.c_customer_id, '-', ca.ca_city)
),
return_keys AS (
  SELECT
    CONCAT(c.c_customer_id, '-', ca.ca_city) AS cust_key
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE regexp_like(r.r_reason_desc, 'price')
)
SELECT cp.cust_key, cp.code, cp.total_profit
FROM cust_profit cp
EXCEPT
SELECT cp.cust_key, cp.code, cp.total_profit
FROM cust_profit cp
JOIN return_keys rk ON cp.cust_key = rk.cust_key
ORDER BY total_profit DESC
LIMIT 100
