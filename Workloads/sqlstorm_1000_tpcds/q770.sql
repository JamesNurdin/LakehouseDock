SELECT
  ws.ws_order_number,
  ws.ws_quantity,
  concat_ws(' - ', i.i_product_name, i.i_item_id) AS product_info,
  lower(i.i_product_name) AS product_name_lc,
  upper(i.i_product_name) AS product_name_uc,
  substr(i.i_item_desc, 1, 15) AS item_desc_prefix,
  regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '') AS item_desc_clean,
  length(i.i_item_desc) AS item_desc_len,
  p.p_promo_name,
  replace(p.p_promo_name, ' ', '_') AS promo_name_underscore,
  lower(p.p_promo_name) AS promo_name_lower,
  wp.wp_url,
  replace(wp.wp_url, 'http://', '') AS url_no_http,
  split(wp.wp_url, '\\/') AS url_parts,
  array_join(split(wp.wp_url, '\\/'), '|') AS url_joined,
  sm.sm_ship_mode_id,
  replace(sm.sm_type, ' ', '-') AS ship_type_hyphen,
  w.w_warehouse_name,
  replace(w.w_warehouse_name, ' ', '') AS w_name_nospace,
  d.d_day_name,
  lower(d.d_day_name) AS d_day_name_lower,
  d.d_quarter_name,
  upper(d.d_quarter_name) AS d_quarter_name_upper,
  date_format(d.d_date, '%Y-%m-%d') AS d_date_str,
  format('%s:%02d %s', t.t_hour, t.t_minute, t.t_am_pm) AS t_time_str,
  wsit.web_name,
  replace(lower(wsit.web_name), ' ', '-') AS web_name_slug,
  (SELECT cp.cp_description FROM catalog_page cp WHERE cp.cp_catalog_page_sk = 1) AS cp_desc,
  regexp_replace((SELECT cp.cp_description FROM catalog_page cp WHERE cp.cp_catalog_page_sk = 1), '\\s+', ' ') AS cp_desc_clean,
  (SELECT replace(lower(cc_name), ' ', '_') FROM call_center WHERE cc_call_center_sk = 1) AS cc_name_slug,
  concat_ws(' || ',
    concat_ws(' - ', i.i_product_name, i.i_item_id),
    replace(p.p_promo_name, ' ', '_'),
    regexp_replace((SELECT cp.cp_description FROM catalog_page cp WHERE cp.cp_catalog_page_sk = 1), '\\s+', ' '),
    array_join(split(wp.wp_url, '\\/'), '|'),
    replace(w.w_warehouse_name, ' ', ''),
    lower(d.d_day_name),
    format('%s:%02d %s', t.t_hour, t.t_minute, t.t_am_pm),
    replace(lower(wsit.web_name), ' ', '-'),
    (SELECT replace(lower(cc_name), ' ', '_') FROM call_center WHERE cc_call_center_sk = 1)
  ) AS benchmark_string,
  row_number() OVER (PARTITION BY ws.ws_warehouse_sk ORDER BY ws.ws_order_number) AS row_seq,
  count(*) OVER (PARTITION BY ws.ws_warehouse_sk) AS warehouse_order_cnt
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
WHERE ws.ws_order_number IS NOT NULL
