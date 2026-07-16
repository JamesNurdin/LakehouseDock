WITH customer_products AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_email_address,
    c.c_preferred_cust_flag,
    concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
    concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type,
              ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address,
    array_agg(DISTINCT i.i_product_name) AS product_names,
    array_agg(DISTINCT i.i_color) AS product_colors
  FROM
    customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE
    c.c_preferred_cust_flag = 'Y'
  GROUP BY
    c.c_customer_sk,
    c.c_customer_id,
    c.c_email_address,
    c.c_preferred_cust_flag,
    c.c_first_name,
    c.c_last_name,
    ca.ca_street_number,
    ca.ca_street_name,
    ca.ca_street_type,
    ca.ca_suite_number,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip
),
store_agg AS (
  SELECT
    ss.ss_customer_sk,
    sum(ss.ss_net_paid) AS total_spent,
    count(*) AS transaction_count
  FROM
    store_sales ss
  GROUP BY
    ss.ss_customer_sk
)
SELECT
  cp.c_customer_id,
  cp.full_name,
  lower(cp.full_name) AS full_name_lower,
  length(cp.full_name) AS full_name_len,
  lower(cp.c_email_address) AS email_lower,
  regexp_extract(cp.c_email_address, '@(.+)$', 1) AS email_domain,
  cp.full_address,
  trim(cp.full_address) AS trimmed_address,
  length(cp.full_address) AS address_len,
  array_join(cp.product_names, '|') AS product_names_concat,
  length(array_join(cp.product_names, '|')) AS product_names_len,
  regexp_replace(array_join(cp.product_names, '|'), '[^A-Za-z0-9|]', '') AS product_names_clean,
  cardinality(array_distinct(cp.product_colors)) AS distinct_color_count,
  concat(cp.c_customer_id, '-', substring(cp.full_address, 1, 3), '-', cast(cardinality(array_distinct(cp.product_colors)) as varchar)) AS customer_code,
  case
    when regexp_like(array_join(cp.product_names, '|'), '.*[0-9]{3}.*') then true else false
  end AS has_three_digit_seq_in_products,
  row_number() OVER (ORDER BY length(array_join(cp.product_names, '|')) DESC) AS prod_name_len_rank,
  coalesce(sa.total_spent, 0) AS total_spent,
  coalesce(sa.transaction_count, 0) AS transaction_count
FROM
  customer_products cp
  LEFT JOIN store_agg sa ON cp.c_customer_sk = sa.ss_customer_sk
WHERE
  cp.full_name IS NOT NULL
ORDER BY
  prod_name_len_rank
LIMIT 100
