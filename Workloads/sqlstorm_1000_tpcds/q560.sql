WITH ss AS (
  SELECT
    ss_sold_date_sk AS sold_date_sk,
    ss_sold_time_sk AS sold_time_sk,
    ss_item_sk AS item_sk,
    ss_store_sk AS loc_sk,
    ss_customer_sk AS customer_sk,
    ss_promo_sk AS promo_sk,
    ss_net_paid AS net_paid,
    ss_net_profit AS net_profit
  FROM store_sales
),
cs AS (
  SELECT
    cs_sold_date_sk AS sold_date_sk,
    cs_sold_time_sk AS sold_time_sk,
    cs_item_sk AS item_sk,
    cs_call_center_sk AS loc_sk,
    cs_promo_sk AS promo_sk,
    cs_net_paid AS net_paid,
    cs_net_profit AS net_profit
  FROM catalog_sales
),
ws AS (
  SELECT
    ws_sold_date_sk AS sold_date_sk,
    ws_sold_time_sk AS sold_time_sk,
    ws_item_sk AS item_sk,
    ws_web_page_sk AS loc_sk,
    ws_promo_sk AS promo_sk,
    ws_net_paid AS net_paid,
    ws_net_profit AS net_profit
  FROM web_sales
),
joined AS (
  SELECT
    'store' AS channel,
    sold_date_sk,
    sold_time_sk,
    item_sk,
    loc_sk,
    customer_sk,
    promo_sk,
    net_paid,
    net_profit
  FROM ss
  UNION ALL
  SELECT
    'catalog' AS channel,
    sold_date_sk,
    sold_time_sk,
    item_sk,
    loc_sk,
    NULL AS customer_sk,
    promo_sk,
    net_paid,
    net_profit
  FROM cs
  UNION ALL
  SELECT
    'web' AS channel,
    sold_date_sk,
    sold_time_sk,
    item_sk,
    loc_sk,
    NULL AS customer_sk,
    promo_sk,
    net_paid,
    net_profit
  FROM ws
)

SELECT
  j.channel,
  d.d_year,
  t.t_hour,
  CASE
    WHEN j.channel = 'store' THEN s.s_store_name
    WHEN j.channel = 'catalog' THEN cc.cc_name
    WHEN j.channel = 'web' THEN wp.wp_url
    ELSE NULL
  END AS location_name_raw,
  lower(regexp_replace(
    CASE
      WHEN j.channel = 'store' THEN s.s_store_name
      WHEN j.channel = 'catalog' THEN cc.cc_name
      WHEN j.channel = 'web' THEN wp.wp_url
      ELSE ''
    END,
    '[^a-z0-9]', ''
  )) AS location_name_clean,
  length(
    CASE
      WHEN j.channel = 'store' THEN s.s_store_name
      WHEN j.channel = 'catalog' THEN cc.cc_name
      WHEN j.channel = 'web' THEN wp.wp_url
      ELSE ''
    END
  ) AS location_name_len,
  i.i_product_name,
  regexp_replace(lower(i.i_product_name), '[^a-z0-9]', '') AS product_name_clean,
  substr(i.i_product_name, 1, 6) AS product_prefix,
  length(i.i_product_name) AS product_name_len,
  split(i.i_product_name, ' ') AS product_name_tokens,
  cardinality(split(i.i_product_name, ' ')) AS product_token_count,
  regexp_extract(i.i_product_name, '(\\w+)\\s+(\\w+)', 2) AS product_second_word,
  p.p_promo_name,
  lower(p.p_promo_name) AS promo_name_lower,
  replace(p.p_promo_name, 'Discount', '') AS promo_name_no_discount,
  CASE WHEN regexp_like(p.p_promo_name, '.*% off.*') THEN 1 ELSE 0 END AS is_percent_off_promo,
  coalesce(c.c_first_name, '') AS cust_first_name,
  coalesce(c.c_last_name, '') AS cust_last_name,
  concat_ws(' ', c.c_first_name, c.c_last_name) AS cust_full_name,
  lower(concat_ws(' ', c.c_first_name, c.c_last_name)) AS cust_full_name_lower,
  regexp_replace(ca.ca_address_id, '-', '') AS address_id_no_dash,
  element_at(split(ca.ca_zip, '-'), 1) AS zip_prefix,
  d.d_day_name,
  lower(d.d_day_name) AS day_name_lower,
  replace(d.d_day_name, 'Day', '') AS day_name_no_day,
  t.t_am_pm,
  row_number() OVER (PARTITION BY j.channel, d.d_year ORDER BY j.net_paid DESC) AS rn,
  sum(j.net_paid) OVER (PARTITION BY j.channel, d.d_year) AS sum_net_paid_year,
  avg(j.net_profit) OVER (PARTITION BY j.channel, d.d_year) AS avg_net_profit_year
FROM joined j
LEFT JOIN date_dim d ON d.d_date_sk = j.sold_date_sk
LEFT JOIN time_dim t ON t.t_time_sk = j.sold_time_sk
LEFT JOIN item i ON i.i_item_sk = j.item_sk
LEFT JOIN promotion p ON p.p_promo_sk = j.promo_sk
LEFT JOIN store s ON s.s_store_sk = j.loc_sk AND j.channel = 'store'
LEFT JOIN call_center cc ON cc.cc_call_center_sk = j.loc_sk AND j.channel = 'catalog'
LEFT JOIN web_page wp ON wp.wp_web_page_sk = j.loc_sk AND j.channel = 'web'
LEFT JOIN customer c ON c.c_customer_sk = j.customer_sk
LEFT JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE
  (j.channel = 'store' AND s.s_state IS NOT NULL) OR
  (j.channel = 'catalog' AND cc.cc_state IS NOT NULL) OR
  (j.channel = 'web' AND wp.wp_url IS NOT NULL)
ORDER BY
  j.channel,
  d.d_year,
  rn
LIMIT 100
