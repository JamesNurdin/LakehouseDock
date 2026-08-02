WITH sales_filtered AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_net_paid,
    ss.ss_ext_sales_price,
    ss.ss_quantity,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    d.d_year,
    hd.hd_buy_potential,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_zip AS store_zip,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    SUBSTRING(s.s_zip, 1, 3) AS store_zip_prefix
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2002
    AND REGEXP_LIKE(ca.ca_city, '^[AEIOU].*')
    AND ca.ca_zip LIKE '9%'
)
SELECT
  ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS row_num,
  store_location,
  store_zip_prefix,
  s_store_name,
  total_net_paid,
  total_transactions,
  avg_transaction_value,
  first_discount_term
FROM (
  SELECT
    sf.store_location,
    sf.store_zip_prefix,
    sf.s_store_name,
    SUM(sf.ss_net_paid) AS total_net_paid,
    COUNT(*) AS total_transactions,
    AVG(sf.ss_net_paid) AS avg_transaction_value,
    (
      SELECT REGEXP_EXTRACT(cp.cp_description, '(?i)discount\\s*(\\w*)')
      FROM catalog_page cp
      WHERE cp.cp_department = 'Electronics'
        AND REGEXP_LIKE(cp.cp_description, '(?i)discount')
      LIMIT 1
    ) AS first_discount_term
  FROM sales_filtered sf
  GROUP BY sf.store_location, sf.store_zip_prefix, sf.s_store_name
) agg
ORDER BY total_net_paid DESC
LIMIT 10
