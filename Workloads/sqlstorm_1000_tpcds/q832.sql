WITH unified_sales AS (
  SELECT
    'store' AS sales_channel,
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_item_sk AS item_sk,
    CAST(NULL AS INTEGER) AS call_center_sk,
    ss.ss_store_sk AS store_sk,
    CAST(NULL AS INTEGER) AS web_page_sk,
    CAST(NULL AS INTEGER) AS catalog_page_sk,
    ss.ss_promo_sk AS promo_sk,
    ss.ss_ticket_number AS ticket_number,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit
  FROM store_sales ss
  UNION ALL
  SELECT
    'catalog' AS sales_channel,
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_call_center_sk,
    CAST(NULL AS INTEGER),
    CAST(NULL AS INTEGER),
    cs.cs_catalog_page_sk,
    cs.cs_promo_sk,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit
  FROM catalog_sales cs
  UNION ALL
  SELECT
    'web' AS sales_channel,
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    CAST(NULL AS INTEGER),
    CAST(NULL AS INTEGER),
    ws.ws_web_page_sk,
    CAST(NULL AS INTEGER),
    ws.ws_promo_sk,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit
  FROM web_sales ws
),
enriched_sales AS (
  SELECT
    us.sales_channel,
    us.date_sk,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_product_name,
    i.i_item_desc,
    i.i_color,
    i.i_brand,
    p.p_promo_name,
    cc.cc_name,
    cc.cc_hours,
    s.s_store_name,
    s.s_hours,
    wp.wp_url,
    cp.cp_description,
    us.quantity,
    us.net_paid,
    us.net_profit
  FROM unified_sales us
  LEFT JOIN date_dim d ON us.date_sk = d.d_date_sk
  LEFT JOIN item i ON us.item_sk = i.i_item_sk
  LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
  LEFT JOIN call_center cc ON us.call_center_sk = cc.cc_call_center_sk
  LEFT JOIN store s ON us.store_sk = s.s_store_sk
  LEFT JOIN web_page wp ON us.web_page_sk = wp.wp_web_page_sk
  LEFT JOIN catalog_page cp ON us.catalog_page_sk = cp.cp_catalog_page_sk
)
SELECT
  d_year,
  d_month_seq,
  sales_channel,
  i_category,
  sum(quantity) AS total_quantity,
  sum(net_paid) AS total_sales,
  avg(net_profit) AS avg_profit,
  any_value(lower(i_product_name)) AS product_name_lower,
  any_value(substring(i_product_name, 1, 10)) AS product_name_prefix,
  any_value(length(i_item_desc)) AS item_desc_len,
  any_value(cardinality(split(i_item_desc, ' '))) AS item_desc_word_cnt,
  any_value(regexp_replace(i_item_desc, '[^A-Za-z0-9 ]', '')) AS item_desc_alnum,
  any_value(CASE WHEN i_color LIKE '%RED%' THEN 'RED' ELSE 'NON-RED' END) AS color_flag,
  any_value(replace(p_promo_name, ' ', '_')) AS promo_name_underscored,
  any_value(substring(p_promo_name, length(p_promo_name) - 4, 5)) AS promo_name_last5,
  any_value(regexp_extract(p_promo_name, '([0-9]+)', 1)) AS promo_name_digits,
  any_value(CASE WHEN sales_channel = 'catalog' THEN reverse(cc_name) END) AS cc_name_rev,
  any_value(CASE WHEN sales_channel = 'store' THEN upper(s_store_name) END) AS store_name_upper,
  any_value(CASE WHEN sales_channel = 'web' THEN regexp_replace(wp_url, '^https?://', '') END) AS url_no_proto,
  any_value(CASE WHEN sales_channel = 'catalog' THEN regexp_replace(cp_description, '\\s+', ' ') END) AS cp_desc_clean,
  sum(CASE WHEN sales_channel = 'catalog' THEN quantity ELSE 0 END) AS catalog_quantity,
  sum(CASE WHEN sales_channel = 'store' THEN quantity ELSE 0 END) AS store_quantity,
  sum(CASE WHEN sales_channel = 'web' THEN quantity ELSE 0 END) AS web_quantity,
  count(*) AS rows_processed,
  array_agg(i_product_name) AS product_names,
  transform(array_agg(i_product_name), x -> lower(x)) AS product_names_lower_array,
  cardinality(array_agg(i_product_name)) AS product_name_count
FROM enriched_sales
GROUP BY
  d_year,
  d_month_seq,
  sales_channel,
  i_category
ORDER BY
  total_sales DESC
LIMIT 100
