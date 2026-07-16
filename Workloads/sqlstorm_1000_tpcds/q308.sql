SELECT
  ca.ca_state AS state,
  d.d_year AS year,
  COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
  SUM(ss.ss_net_paid) AS total_sales,
  ROUND(AVG(LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name))), 2) AS avg_full_name_len,
  SUM(CASE WHEN regexp_like(lower(c.c_email_address), '@gmail\\.com$') THEN 1 ELSE 0 END) AS gmail_customers,
  ROUND(AVG(levenshtein_distance(lower(c.c_first_name), 'john')), 2) AS avg_levenshtein_firstname_john,
  COUNT(DISTINCT i.i_category) AS distinct_categories,
  ROUND(AVG(CARDINALITY(split(i.i_item_desc, '\\s+'))), 2) AS avg_desc_word_count,
  MAX(LENGTH(regexp_replace(c.c_login, '[^0-9]', ''))) AS max_digits_in_login,
  MIN(CASE WHEN regexp_like(c.c_login, '^[A-Z]{2}[0-9]{4}$') THEN c.c_login END) AS min_alpha_numeric_login,
  COUNT(DISTINCT regexp_extract(c.c_email_address, '@(.+)$', 1)) AS distinct_email_domains,
  ROUND(AVG(LENGTH(regexp_replace(i.i_item_desc, '[^A-Za-z]', ''))), 2) AS avg_alpha_chars_in_desc,
  ROUND(AVG(LENGTH(i.i_product_name) - LENGTH(regexp_replace(i.i_product_name, '[aeiouAEIOU]', ''))), 2) AS avg_vowel_count_in_product_name,
  ROUND(AVG(LENGTH(regexp_replace(i.i_item_id, '[^0-9]', ''))), 2) AS avg_numeric_chars_in_item_id
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY ca.ca_state, d.d_year
ORDER BY total_sales DESC
LIMIT 100
