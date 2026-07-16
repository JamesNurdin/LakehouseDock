WITH cleaned_items AS (
  SELECT
    i.i_item_sk,
    lower(regexp_replace(i.i_product_name, '[^a-zA-Z0-9 ]', '')) AS clean_name,
    substr(i.i_item_id, 1, 5) AS short_item_id,
    concat(substr(i.i_brand, 1, 3), lower(i.i_color)) AS brand_color_code,
    lower(regexp_extract(i.i_product_name, '^([^ ]+)', 1)) AS first_word
  FROM item i
),
store_daily AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    concat_ws(', ', s.s_street_number, s.s_street_name, s.s_city, s.s_state, s.s_zip) AS store_address,
    lower(regexp_replace(s.s_manager, '[^a-zA-Z]', '')) AS manager_alpha,
    format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM-dd') AS sold_date_str,
    ci.short_item_id,
    ci.brand_color_code,
    ci.first_word,
    ss.ss_net_paid,
    ss.ss_net_profit
  FROM store s
  JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN cleaned_items ci ON ss.ss_item_sk = ci.i_item_sk
  WHERE d.d_year = 2002
),
aggregated AS (
  SELECT
    s_store_id,
    s_store_name,
    store_address,
    manager_alpha,
    array_join(array_agg(DISTINCT short_item_id ORDER BY short_item_id), ',') AS sku_list,
    array_join(array_agg(DISTINCT brand_color_code ORDER BY brand_color_code), '|') AS brand_color_codes,
    array_join(array_agg(DISTINCT first_word ORDER BY first_word), ',') AS first_words,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
  FROM store_daily
  GROUP BY
    s_store_id,
    s_store_name,
    store_address,
    manager_alpha
)
SELECT
  s_store_id,
  s_store_name,
  store_address,
  manager_alpha,
  sku_list,
  brand_color_codes,
  first_words,
  total_net_paid,
  total_net_profit,
  transaction_count
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 10
