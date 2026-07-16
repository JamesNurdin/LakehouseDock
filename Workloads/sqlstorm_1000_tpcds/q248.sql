WITH sales_enriched AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_store_sk,
    ss.ss_promo_sk,
    d.d_year,
    s.s_store_name,
    s.s_city,
    s.s_state,
    c.c_first_name,
    c.c_last_name,
    i.i_product_name,
    i.i_item_desc,
    p.p_promo_name
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE ss.ss_quantity > 0
),
string_processed AS (
  SELECT
    d_year,
    s_store_name,
    s_city,
    s_state,
    c_first_name,
    c_last_name,
    i_product_name,
    i_item_desc,
    p_promo_name,
    ss_quantity,
    ss_net_paid,
    concat_ws(' - ', s_store_name, s_city, s_state) AS store_location,
    concat(upper(substr(c_first_name, 1, 1)), lower(substr(c_last_name, 1, 1)), '.') AS name_initials,
    lower(replace(concat(c_first_name, ' ', c_last_name), ' ', '_')) AS normalized_full_name,
    regexp_replace(i_product_name, '[^A-Za-z0-9 ]', '') AS clean_product_name,
    split(i_item_desc, ' ')[1] AS first_word_desc,
    length(i_item_desc) AS product_desc_len,
    CASE
      WHEN p_promo_name IS NULL THEN 'NoPromo'
      ELSE regexp_extract(p_promo_name, '(\\w+)', 1)
    END AS promo_code,
    format('%.2f', ss_net_paid) AS net_paid_formatted,
    row_number() OVER (PARTITION BY d_year ORDER BY ss_net_paid DESC) AS rn_year,
    substr(i_product_name, 1, 3) AS product_name_prefix,
    replace(i_item_desc, ' ', '-') AS hyphenated_desc,
    trim(concat_ws(', ', s_store_name, s_city)) AS trimmed_store,
    format('Qty:%s Net:%s', CAST(ss_quantity AS VARCHAR), format('%.2f', ss_net_paid)) AS qty_net_string,
    concat(CAST(ss_net_paid AS VARCHAR), '_', CAST(ss_quantity AS VARCHAR)) AS net_quantity_concat,
    regexp_replace(lower(i_item_desc), '(\\b\\w{1}\\b)', '') AS removed_single_letter_words,
    array_join(split(i_product_name, ' '), '|') AS product_name_pipe_separated
  FROM sales_enriched
)
SELECT
  d_year,
  store_location,
  name_initials,
  normalized_full_name,
  clean_product_name,
  first_word_desc,
  product_desc_len,
  promo_code,
  net_paid_formatted,
  rn_year,
  product_name_prefix,
  hyphenated_desc,
  trimmed_store,
  qty_net_string,
  net_quantity_concat,
  removed_single_letter_words,
  product_name_pipe_separated
FROM string_processed
WHERE rn_year <= 10
ORDER BY d_year DESC, rn_year
LIMIT 50
