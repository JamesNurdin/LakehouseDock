WITH transformed AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_quantity,
    ss.ss_sales_price,
    i.i_product_name,
    i.i_color,
    i.i_size,
    i.i_formulation,
    s.s_city,
    s.s_state,
    s.s_zip,
    s.s_gmt_offset,
    lower(i.i_product_name) AS product_name_lower,
    upper(i.i_product_name) AS product_name_upper,
    length(i.i_product_name) AS product_name_len,
    reverse(i.i_product_name) AS product_name_rev,
    regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '') AS product_name_alnum,
    substring(i.i_product_name FROM 1 FOR 5) AS product_name_prefix,
    regexp_extract(i.i_product_name, '([A-Za-z]+)([0-9]+)', 2) AS product_name_number_part,
    replace(i.i_product_name, ' ', '_') AS product_name_underscore,
    concat_ws(' ', s.s_city, s.s_state, s.s_zip) AS store_location,
    CAST(s.s_gmt_offset AS varchar) AS store_gmt_str,
    array_join(split(i.i_product_name, ' '), '|') AS product_name_split_joined,
    trim(i.i_product_name) AS product_name_trim,
    translate(i.i_product_name, 'AEIOUaeiou', '**********') AS product_name_consonants_masked,
    concat(
       substr(i.i_color, 1, 1),
       substr(i.i_size, 1, 1),
       substr(i.i_formulation, 1, 1)
    ) AS csf_initials,
    replace(
        concat(i.i_product_name, '-', i.i_color, '-', i.i_size),
        ' ', ''
    ) AS product_combined_nospace,
    CASE WHEN i.i_product_name LIKE '%SPECIAL%' THEN 'YES' ELSE 'NO' END AS special_flag,
    CASE WHEN regexp_like(i.i_product_name, '^[A-Z]{3}[0-9]{2}$') THEN 1 ELSE 0 END AS is_code_pattern
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
)
SELECT
  store_location,
  count(*) AS total_transactions,
  sum(ss_quantity) AS total_quantity,
  sum(ss_sales_price) AS total_sales,
  avg(product_name_len) AS avg_product_name_len,
  max(CASE WHEN special_flag = 'YES' THEN ss_sales_price ELSE NULL END) AS max_special_price,
  sum(CASE WHEN is_code_pattern = 1 THEN 1 ELSE 0 END) AS code_pattern_count,
  approx_distinct(concat(product_name_alnum, '-', store_gmt_str)) AS distinct_key_est,
  concat_ws('||',
    lower(product_name_prefix),
    product_name_rev,
    csf_initials,
    product_combined_nospace,
    store_location
  ) AS benchmark_string
FROM transformed
GROUP BY
  store_location,
  product_name_alnum,
  store_gmt_str,
  product_name_prefix,
  product_name_rev,
  csf_initials,
  product_combined_nospace
ORDER BY total_sales DESC
LIMIT 50
