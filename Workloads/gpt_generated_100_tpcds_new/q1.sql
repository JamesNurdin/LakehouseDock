WITH filtered1 AS (
  SELECT c.c_customer_id
  FROM tpcds.customer c
  JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE ca.ca_zip = '79584'
    AND c.c_first_sales_date_sk BETWEEN 2450000 AND 2452000
),
filtered2 AS (
  SELECT c.c_customer_id
  FROM tpcds.customer c
  JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE ca.ca_county = 'Madison County'
    AND c.c_preferred_cust_flag = 'Y'
)
SELECT i.c_customer_id,
       d.segment
FROM (
  SELECT c_customer_id FROM filtered1
  INTERSECT
  SELECT c_customer_id FROM filtered2
) i
CROSS JOIN (
  VALUES ('HighValue'), ('LowValue')
) AS d(segment)
ORDER BY i.c_customer_id
LIMIT 100
