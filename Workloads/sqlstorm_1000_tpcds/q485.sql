WITH base AS (
  SELECT
    'catalog' AS channel,
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_order_number AS order_number,
    cs.cs_item_sk AS item_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    i.i_product_name AS product_name,
    i.i_color AS product_color,
    i.i_size AS product_size,
    i.i_category AS product_category,
    cc.cc_state AS state,
    lower(i.i_product_name) AS prod_name_lc,
    regexp_replace(lower(i.i_product_name), '[^a-z0-9]', '_') AS prod_name_norm,
    substr(i.i_product_name, 1, 8) AS prod_prefix,
    CASE WHEN length(i.i_product_name) >= 8 THEN substr(i.i_product_name, length(i.i_product_name) - 7, 8) ELSE i.i_product_name END AS prod_suffix,
    length(i.i_product_name) AS prod_len,
    cardinality(split(i.i_product_name, ' ')) AS prod_word_cnt,
    regexp_extract(i.i_product_name, '(\\d+)', 1) AS prod_num,
    reverse(i.i_product_name) AS prod_rev,
    array_join(array_sort(split(i.i_product_name, ' ')), '_') AS prod_fingerprint,
    concat_ws('-', cc.cc_state, i.i_category, i.i_color) AS concat_key,
    replace(concat_ws('_', cc.cc_state, i.i_category, i.i_color), ' ', '') AS replace_key,
    regexp_replace(concat_ws('-', cc.cc_state, i.i_category, i.i_color), '[^A-Z]', '') AS regex_key
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
),
base2 AS (
  SELECT
    'store' AS channel,
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_ticket_number AS order_number,
    ss.ss_item_sk AS item_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    i.i_product_name AS product_name,
    i.i_color AS product_color,
    i.i_size AS product_size,
    i.i_category AS product_category,
    s.s_state AS state,
    lower(i.i_product_name) AS prod_name_lc,
    regexp_replace(lower(i.i_product_name), '[^a-z0-9]', '_') AS prod_name_norm,
    substr(i.i_product_name, 1, 8) AS prod_prefix,
    CASE WHEN length(i.i_product_name) >= 8 THEN substr(i.i_product_name, length(i.i_product_name) - 7, 8) ELSE i.i_product_name END AS prod_suffix,
    length(i.i_product_name) AS prod_len,
    cardinality(split(i.i_product_name, ' ')) AS prod_word_cnt,
    regexp_extract(i.i_product_name, '(\\d+)', 1) AS prod_num,
    reverse(i.i_product_name) AS prod_rev,
    array_join(array_sort(split(i.i_product_name, ' ')), '_') AS prod_fingerprint,
    concat_ws('-', s.s_state, i.i_category, i.i_color) AS concat_key,
    replace(concat_ws('_', s.s_state, i.i_category, i.i_color), ' ', '') AS replace_key,
    regexp_replace(concat_ws('-', s.s_state, i.i_category, i.i_color), '[^A-Z]', '') AS regex_key
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
),
base3 AS (
  SELECT
    'web' AS channel,
    ws.ws_sold_date_sk AS date_sk,
    ws.ws_order_number AS order_number,
    ws.ws_item_sk AS item_sk,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    i.i_product_name AS product_name,
    i.i_color AS product_color,
    i.i_size AS product_size,
    i.i_category AS product_category,
    wsite.web_state AS state,
    lower(i.i_product_name) AS prod_name_lc,
    regexp_replace(lower(i.i_product_name), '[^a-z0-9]', '_') AS prod_name_norm,
    substr(i.i_product_name, 1, 8) AS prod_prefix,
    CASE WHEN length(i.i_product_name) >= 8 THEN substr(i.i_product_name, length(i.i_product_name) - 7, 8) ELSE i.i_product_name END AS prod_suffix,
    length(i.i_product_name) AS prod_len,
    cardinality(split(i.i_product_name, ' ')) AS prod_word_cnt,
    regexp_extract(i.i_product_name, '(\\d+)', 1) AS prod_num,
    reverse(i.i_product_name) AS prod_rev,
    array_join(array_sort(split(i.i_product_name, ' ')), '_') AS prod_fingerprint,
    concat_ws('-', wsite.web_state, i.i_category, i.i_color) AS concat_key,
    replace(concat_ws('_', wsite.web_state, i.i_category, i.i_color), ' ', '') AS replace_key,
    regexp_replace(concat_ws('-', wsite.web_state, i.i_category, i.i_color), '[^A-Z]', '') AS regex_key
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
),
unified AS (
  SELECT * FROM base
  UNION ALL
  SELECT * FROM base2
  UNION ALL
  SELECT * FROM base3
)
SELECT
  d.d_year,
  d.d_month_seq AS month_seq,
  u.channel,
  u.state,
  substring(u.concat_key, 1, 3) AS state_prefix,
  sum(u.net_paid) AS total_net_paid,
  avg(u.net_paid) AS avg_net_paid,
  sum(u.quantity) AS total_quantity,
  avg(u.prod_len) AS avg_product_name_length,
  max(u.prod_len) AS max_product_name_length,
  count(DISTINCT u.item_sk) AS distinct_products_sold,
  approx_distinct(u.prod_fingerprint) AS approx_distinct_fingerprints,
  max_by(u.prod_prefix, u.net_paid) AS top_product_prefix,
  max_by(u.prod_name_norm, u.net_paid) AS most_common_norm_name
FROM unified u
JOIN date_dim d ON u.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY
  d.d_year,
  d.d_month_seq,
  u.channel,
  u.state,
  substring(u.concat_key, 1, 3)
ORDER BY
  d.d_year,
  d.d_month_seq,
  u.channel,
  total_net_paid DESC
