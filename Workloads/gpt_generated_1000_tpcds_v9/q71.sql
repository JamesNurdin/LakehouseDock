WITH filtered_sales AS (
  SELECT
    sa.ss_sold_date_sk,
    sa.ss_addr_sk,
    sa.ss_ext_sales_price,
    sa.ss_ext_discount_amt,
    sa.ss_net_paid_inc_tax,
    sa.ss_quantity,
    ca.ca_city,
    ca.ca_state,
    ca.ca_address_id,
    ca.ca_zip,
    dd.d_year,
    dd.d_current_quarter
  FROM store_sales sa
  JOIN customer_address ca
    ON sa.ss_addr_sk = ca.ca_address_sk
  JOIN date_dim dd
    ON sa.ss_sold_date_sk = dd.d_date_sk
  WHERE regexp_like(ca.ca_city, '^Oak')
    AND ca.ca_address_id LIKE 'AAAAAAA%'
    AND dd.d_current_quarter = 'Y'
)
SELECT
  ca_city,
  ca_state,
  d_year,
  regexp_extract(ca_city, '(Oak.*)', 1) AS oak_city,
  CONCAT(ca_city, ', ', ca_state) AS city_state,
  SUM(ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
  SUM(ss_ext_sales_price) AS total_ext_sales_price,
  AVG(ss_ext_discount_amt) AS avg_discount_amt,
  SUM(ss_quantity) AS total_quantity,
  COUNT(*) AS transaction_count
FROM filtered_sales
GROUP BY
  ca_city,
  ca_state,
  d_year,
  regexp_extract(ca_city, '(Oak.*)', 1),
  CONCAT(ca_city, ', ', ca_state)
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
