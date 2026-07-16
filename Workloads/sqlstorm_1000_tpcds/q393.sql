SELECT
  s.s_store_id,
  s.s_store_name,
  concat_ws(', ', s.s_state, s.s_country) AS store_location,
  replace(lower(s.s_store_name), ' ', '-') AS store_slug,
  i.i_item_id,
  i.i_product_name,
  regexp_replace(i.i_product_name, '[aeiouAEIOU]', '*') AS product_name_masked_vowels,
  length(i.i_product_name) AS product_name_len,
  length(regexp_replace(i.i_product_name, '[^A-Za-z]', '')) AS product_alpha_len,
  substr(i.i_product_name, 1, 5) AS product_name_prefix,
  concat(substr(i.i_product_name, 1, 1), lower(substr(i.i_product_name, 2))) AS product_name_proper,
  regexp_like(i.i_product_name, '^.*[Aa]pple.*$') AS product_has_apple,
  reverse(i.i_product_name) AS product_name_rev,
  i.i_item_desc,
  substr(i.i_item_desc, 1, 10) AS item_desc_start,
  length(i.i_item_desc) AS item_desc_len,
  length(regexp_replace(i.i_item_desc, '[^A-Za-z]', '')) AS item_desc_alpha_len,
  c.c_customer_id,
  concat_ws(' ', c.c_first_name, c.c_last_name) AS customer_full_name,
  regexp_replace(concat_ws(' ', c.c_first_name, c.c_last_name), '[^A-Za-z]', '') AS customer_name_alpha,
  length(regexp_replace(concat_ws(' ', c.c_first_name, c.c_last_name), '[^A-Za-z]', '')) AS customer_name_alpha_len,
  d.d_day_name,
  lower(d.d_day_name) AS day_name_lower,
  CASE WHEN d.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
  CAST(ss.ss_net_paid AS double) AS net_paid,
  row_number() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS store_sales_rank,
  CASE WHEN p.p_promo_name IS NOT NULL THEN concat('Promo: ', regexp_replace(p.p_promo_name, '\s+', ' ')) ELSE NULL END AS promo_desc,
  length(coalesce(p.p_promo_name, '')) AS promo_name_len,
  replace(coalesce(p.p_promo_name, ''), ' ', '_') AS promo_name_underscored,
  regexp_replace(coalesce(p.p_promo_name, ''), '[^A-Za-z]', '') AS promo_alpha,
  length(regexp_replace(coalesce(p.p_promo_name, ''), '[^A-Za-z]', '')) AS promo_alpha_len,
  substr(coalesce(p.p_promo_name, ''), 1, 3) AS promo_prefix,
  reverse(coalesce(p.p_promo_name, '')) AS promo_name_rev,
  split_part(coalesce(p.p_promo_name, ''), ' ', 2) AS promo_second_word
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE ss.ss_sold_date_sk BETWEEN (SELECT max(d_date_sk) - 365 FROM date_dim) AND (SELECT max(d_date_sk) FROM date_dim)
  AND lower(s.s_store_name) LIKE '%store%'
ORDER BY s.s_store_id, store_sales_rank
LIMIT 100
