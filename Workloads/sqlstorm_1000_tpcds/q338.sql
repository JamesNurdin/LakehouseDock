SELECT
  cc.cc_call_center_id,
  concat_ws(' | ',
    trim(cc.cc_name),
    upper(cc.cc_manager),
    concat('Hours ', lower(trim(substr(cc.cc_hours, 1, strpos(cc.cc_hours, '-') - 1))), '-', lower(trim(substr(cc.cc_hours, strpos(cc.cc_hours, '-') + 1)))),
    concat('Opened ', cast(cc.cc_open_date_sk AS varchar)),
    concat('Closed ', cast(cc.cc_closed_date_sk AS varchar))
  ) AS call_center_info,
  concat_ws(', ', lower(c.c_first_name), lower(c.c_last_name), lower(c.c_email_address)) AS customer_info,
  length(concat_ws(' ', i.i_product_name, i.i_item_desc)) AS product_string_len,
  cardinality(regexp_extract_all(i.i_product_name, '\\w+')) AS product_word_count,
  regexp_replace(i.i_product_name, '[AEIOUaeiou]', '*') AS product_name_vowel_masked,
  concat_ws('---',
    concat('Order:', lpad(cast(cs.cs_order_number AS varchar), 12, '0')),
    concat('Promo:', coalesce(p.p_promo_name, 'N/A')),
    concat('Qty:', cast(cs.cs_quantity AS varchar))
  ) AS sales_key,
  concat_ws('---',
    concat('CatalogPage:', cp.cp_type),
    concat('Dept:', cp.cp_department),
    concat('PageNum:', cast(cp.cp_catalog_page_number AS varchar))
  ) AS catalog_info,
  concat_ws(' | ',
    lower(regexp_replace(ca.ca_street_name, '\\s+', '_')),
    lower(regexp_replace(ca.ca_city, '\\s+', '_')),
    lower(ca.ca_state),
    regexp_replace(ca.ca_zip, '\\D', '')
  ) AS normalized_address,
  format('%s_%s', cast(cs.cs_sold_date_sk AS varchar), cast(cs.cs_sold_time_sk AS varchar)) AS sold_timestamp_key
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE cardinality(regexp_extract_all(i.i_product_name, '\\w+')) > 3
ORDER BY product_string_len DESC
LIMIT 100
