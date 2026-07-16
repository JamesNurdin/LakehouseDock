WITH cust_addr AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_salutation,
    c.c_email_address,
    c.c_preferred_cust_flag,
    ca.ca_address_sk,
    ca.ca_street_number,
    ca.ca_street_name,
    ca.ca_street_type,
    ca.ca_suite_number,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.ca_country
  FROM customer c
  JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_agg AS (
  SELECT
    ss.ss_customer_sk,
    sum(ss.ss_net_paid) AS total_spent,
    sum(ss.ss_quantity) AS total_quantity,
    count(*) AS txn_count,
    array_agg(DISTINCT i.i_item_desc) AS item_descs
  FROM store_sales ss
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  GROUP BY ss.ss_customer_sk
),
processed AS (
  SELECT
    ca.c_customer_sk,
    concat_ws(' ', ca.c_salutation, ca.c_first_name, ca.c_last_name) AS full_name,
    lower(concat(
      ca.ca_street_number, ' ',
      ca.ca_street_name, ' ',
      ca.ca_street_type,
      coalesce(concat(' ', ca.ca_suite_number), ''),
      ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip
    )) AS norm_address,
    length(lower(concat_ws(' ', ca.c_first_name, ca.c_last_name))) AS name_len,
    regexp_replace(lower(ca.c_email_address), '[^a-z0-9@.]', '') AS cleaned_email,
    cardinality(split(ca.c_email_address, '@')) AS email_parts,
    element_at(split(ca.c_email_address, '@'), 1) AS email_user,
    element_at(split(ca.c_email_address, '@'), 2) AS email_domain,
    regexp_like(ca.c_email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') AS email_valid,
    CASE WHEN ca.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_tier,
    sales.total_spent,
    sales.total_quantity,
    sales.txn_count,
    cardinality(sales.item_descs) AS distinct_items,
    replace(
      upper(array_join(transform(sales.item_descs, d -> substr(d, 1, 5)), '|')),
      '.', ''
    ) AS item_descs_snippet
  FROM cust_addr ca
  LEFT JOIN sales_agg sales
    ON ca.c_customer_sk = sales.ss_customer_sk
)
SELECT
  full_name,
  norm_address,
  name_len,
  cleaned_email,
  email_user,
  email_domain,
  email_valid,
  cust_tier,
  total_spent,
  total_quantity,
  txn_count,
  distinct_items,
  item_descs_snippet,
  length(regexp_replace(concat_ws(' ', full_name, norm_address, cleaned_email, cust_tier), '\\s+', ' ')) AS total_characters
FROM processed
WHERE email_valid
ORDER BY total_spent DESC
LIMIT 100
