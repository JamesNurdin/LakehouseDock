WITH filtered_sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    cc.cc_zip,
    i.i_item_desc,
    cust.c_customer_sk,
    cust.c_first_name,
    cust.c_last_name,
    cust.c_email_address
  FROM tpcds.catalog_sales cs
  JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.customer cust
    ON cs.cs_bill_customer_sk = cust.c_customer_sk
  WHERE regexp_like(i.i_item_desc, '(?i).* (bike|bicycle).*')
    AND cc.cc_name LIKE '%Center%'
    AND substr(cc.cc_zip, 1, 2) = '98'
)
SELECT
  cc_name,
  cc_city,
  cc_state,
  count(DISTINCT cs_order_number) AS orders,
  sum(cs_ext_sales_price) AS total_sales,
  sum(cs_net_profit) AS total_profit,
  regexp_extract(cc_zip, '(\\d{5})', 1) AS zip_code,
  concat(c_first_name, ' ', c_last_name) AS customer_full_name,
  regexp_extract(c_email_address, '^[^@]+', 1) AS email_user
FROM filtered_sales
GROUP BY
  cc_name,
  cc_city,
  cc_state,
  regexp_extract(cc_zip, '(\\d{5})', 1),
  concat(c_first_name, ' ', c_last_name),
  regexp_extract(c_email_address, '^[^@]+', 1)
ORDER BY total_sales DESC
LIMIT 100
