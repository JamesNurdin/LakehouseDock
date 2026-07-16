SELECT
  lower(regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)) AS domain,
  lower(wp.wp_type) AS page_type,
  format_datetime(date_dim.d_date, 'yyyy-MM-dd') AS sold_date,
  sum(ws.ws_ext_sales_price) AS total_sales,
  sum(ws.ws_net_profit) AS total_profit,
  count(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
  array_join(array_agg(DISTINCT replace(i.i_product_name, ' ', '_')), ', ') AS product_names_underscored,
  array_join(array_agg(DISTINCT i.i_category), ', ') AS categories,
  concat_ws('|',
    lower(regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)),
    lower(wp.wp_type),
    substring(upper(p.p_promo_name), 1, 5)
  ) AS signature,
  avg(levenshtein_distance(lower(i.i_product_name), lower(p.p_promo_name))) AS avg_name_lev_distance,
  sum(ws.ws_quantity) AS total_quantity,
  approx_percentile(ws.ws_ext_sales_price, 0.5) AS median_sales_price,
  count(*) AS order_count,
  cast(count(*) AS double) / nullif(count(DISTINCT ws.ws_bill_customer_sk), 0) AS orders_per_customer,
  array_join(array_distinct(
    split(regexp_replace(i.i_item_desc, '[^A-Za-z0-9]+', ' '), ' ')
  ), ', ') AS distinct_desc_words,
  regexp_replace(i.i_item_desc, '\\s+', ' ') AS normalized_item_desc,
  substring(regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', ''), 1, 30) AS desc_prefix
FROM web_sales ws
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim
  ON ws.ws_sold_date_sk = date_dim.d_date_sk
WHERE ws.ws_ext_sales_price > 0
  AND p.p_discount_active = 'Y'
  AND regexp_like(wp.wp_url, '^https?://')
GROUP BY
  lower(regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)),
  lower(wp.wp_type),
  format_datetime(date_dim.d_date, 'yyyy-MM-dd'),
  p.p_promo_name,
  i.i_item_desc
HAVING sum(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
