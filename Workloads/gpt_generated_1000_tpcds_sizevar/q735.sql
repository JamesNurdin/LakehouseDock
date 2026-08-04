WITH catalog_cust AS (
  SELECT ca.ca_address_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2020
),
web_cust AS (
  SELECT ca.ca_address_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2020
),
store_cust AS (
  SELECT ca.ca_address_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2020
),
intersect_cust AS (
  SELECT ca_address_sk FROM catalog_cust
  INTERSECT
  SELECT ca_address_sk FROM web_cust
),
except_cust AS (
  SELECT ca_address_sk FROM intersect_cust
  EXCEPT
  SELECT ca_address_sk FROM store_cust
),
promo_cust AS (
  SELECT ca.ca_address_sk
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2020
)
SELECT
  COALESCE(e.ca_address_sk, p.ca_address_sk) AS address_sk,
  CASE
    WHEN e.ca_address_sk IS NOT NULL AND p.ca_address_sk IS NOT NULL THEN 'Both'
    WHEN e.ca_address_sk IS NOT NULL THEN 'ExceptOnly'
    ELSE 'PromoOnly'
  END AS source,
  (SELECT COUNT(*)
   FROM catalog_sales cs3
   WHERE cs3.cs_bill_addr_sk = COALESCE(e.ca_address_sk, p.ca_address_sk)) AS catalog_sales_count
FROM except_cust e
FULL OUTER JOIN promo_cust p
  ON e.ca_address_sk = p.ca_address_sk
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_addr_sk = COALESCE(e.ca_address_sk, p.ca_address_sk)
      AND ss.ss_quantity > 5
  )
ORDER BY catalog_sales_count DESC
LIMIT 100
