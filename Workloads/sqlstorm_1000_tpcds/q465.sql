WITH customers AS (
  SELECT
    c.c_customer_sk,
    c.c_email_address,
    lower(c.c_email_address) AS email_lower,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    trim(concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name)) AS full_name,
    reverse(trim(concat_ws(' ', c.c_first_name, c.c_last_name))) AS rev_full_name,
    length(c.c_first_name) + length(c.c_last_name) AS name_len,
    c.c_birth_country,
    c.c_login,
    c.c_preferred_cust_flag,
    c.c_current_addr_sk
  FROM customer c
  WHERE c.c_email_address IS NOT NULL
),
addresses AS (
  SELECT
    ca.ca_address_sk,
    ca.ca_state,
    ca.ca_city,
    trim(both ' ' FROM ca.ca_street_name) AS street_name_clean,
    replace(ca.ca_street_type, 'St', 'Street') AS street_type_norm,
    concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number) AS full_street
  FROM customer_address ca
),
joined AS (
  SELECT
    cu.c_customer_sk,
    cu.email_domain,
    cu.full_name,
    cu.name_len,
    cu.c_login,
    cu.c_preferred_cust_flag,
    ad.ca_state,
    ad.ca_city,
    ad.street_name_clean,
    ad.street_type_norm,
    ad.full_street,
    i.i_item_id,
    i.i_item_desc,
    i.i_product_name,
    i.i_color,
    i.i_size,
    i.i_units,
    i.i_container,
    i.i_manager_id,
    cp.cp_description,
    cp.cp_type,
    cc.cc_name,
    cc.cc_hours,
    d.d_date
  FROM customers cu
  LEFT JOIN addresses ad ON cu.c_current_addr_sk = ad.ca_address_sk
  LEFT JOIN web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = ws.ws_sold_date_sk
  LEFT JOIN call_center cc ON ws.ws_ship_mode_sk = cc.cc_call_center_sk
  LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT
  email_domain,
  count(*) AS total_customers,
  approx_distinct(c_customer_sk) AS distinct_customers,
  max_by(full_name, name_len) AS longest_full_name,
  min(name_len) AS min_name_len,
  max(name_len) AS max_name_len,
  approx_percentile(name_len, 0.5) AS median_name_len,
  array_agg(DISTINCT lower(cc_name)) FILTER (WHERE cc_name IS NOT NULL) AS call_center_names,
  array_agg(DISTINCT regexp_replace(cc_hours, '\\d', 'X')) FILTER (WHERE cc_hours IS NOT NULL) AS call_center_hours_masked,
  array_agg(DISTINCT replace(cp_type, '.', '')) FILTER (WHERE cp_type IS NOT NULL) AS catalog_page_types,
  array_agg(DISTINCT split_part(cp_description, ' ', 1)) FILTER (WHERE cp_description IS NOT NULL) AS cp_first_words,
  array_agg(DISTINCT substring(i_item_desc, 1, 15)) FILTER (WHERE i_item_desc IS NOT NULL) AS item_desc_prefixes,
  array_agg(DISTINCT regexp_replace(i_item_desc, '\\s+', ' ')) FILTER (WHERE i_item_desc IS NOT NULL) AS item_desc_normalized,
  array_agg(DISTINCT concat_ws('_', i_color, i_size, i_units)) FILTER (WHERE i_color IS NOT NULL AND i_size IS NOT NULL AND i_units IS NOT NULL) AS color_size_units,
  array_agg(DISTINCT format('%s-%s', i_manager_id, i_item_id)) FILTER (WHERE i_manager_id IS NOT NULL AND i_item_id IS NOT NULL) AS manager_item_pairs,
  array_agg(DISTINCT replace(full_street, 'Street', 'St.')) FILTER (WHERE full_street IS NOT NULL) AS street_normalized,
  array_agg(DISTINCT lower(c_login)) FILTER (WHERE c_login IS NOT NULL) AS login_lowercase,
  array_agg(DISTINCT CASE WHEN c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Regular' END) AS customer_type,
  max(concat_ws(' | ',
    format_datetime(CAST(d_date AS timestamp), 'yyyy-MM-dd'),
    coalesce(cc_name, 'NoCC'),
    coalesce(cp_type, 'NoCP')
  )) AS composite_key
FROM joined
GROUP BY email_domain
HAVING count(*) > 100
ORDER BY total_customers DESC
LIMIT 20
