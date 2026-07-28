WITH sales AS (
  SELECT
    c.c_customer_id AS customer_id,
    cs.cs_sold_date_sk AS transaction_date_sk,
    cs.cs_ext_sales_price AS amount,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.cs_sold_date_sk DESC) AS rank
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE ca.ca_country = 'United States'
    AND cp.cp_type = 'monthly'
    AND cs.cs_ext_sales_price > 0
),
returns AS (
  SELECT
    c.c_customer_id AS customer_id,
    sr.sr_returned_date_sk AS transaction_date_sk,
    -sr.sr_return_amt AS amount,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY sr.sr_returned_date_sk DESC) AS rank
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE ca.ca_country = 'United States'
    AND s.s_rec_end_date > DATE '2000-01-01'
    AND sr.sr_return_amt > 0
)
SELECT
  customer_id,
  transaction_date_sk,
  amount,
  rank
FROM sales
WHERE rank = 1

UNION ALL

SELECT
  customer_id,
  transaction_date_sk,
  amount,
  rank
FROM returns
WHERE rank = 1

ORDER BY amount DESC
LIMIT 100
