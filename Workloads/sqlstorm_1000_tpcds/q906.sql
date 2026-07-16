SELECT
    lower(split_part(c.c_email_address, '@', 2)) AS email_domain,
    regexp_extract(c.c_email_address, '\\.([A-Za-z]+)$', 1) AS email_tld,
    lower(c.c_login) AS login_lower,
    concat_ws(' ', c.c_first_name, c.c_last_name) AS customer_full_name,
    length(concat_ws(' ', c.c_first_name, c.c_last_name)) AS customer_name_len,
    lower(trim(p.p_promo_name)) AS promo_name_clean,
    length(p.p_promo_name) AS promo_name_len,
    concat_ws(' - ', s.s_store_name, s.s_city, s.s_state) AS store_full_name,
    length(s.s_store_name) AS store_name_len,
    substr(s.s_store_name, 1, 3) AS store_name_prefix,
    upper(regexp_replace(cc.cc_name, '\\b(\\w)\\w*\\b', '\\1')) AS cc_name_abbrev,
    replace(cc.cc_hours, '-', ' to ') AS cc_hours_clean,
    concat_ws(', ', s.s_city, s.s_state, s.s_zip) AS store_address,
    lower(i.i_product_name) AS product_name_lower,
    lower(i.i_color) AS product_color_lower,
    lower(i.i_size) AS product_size_lower,
    regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '') AS item_desc_clean,
    length(regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '')) AS item_desc_clean_len,
    lower(wp.wp_url) AS url_lower,
    regexp_extract(wp.wp_url, '^(?:https?://)?([^/]+)', 1) AS url_domain,
    length(regexp_extract(wp.wp_url, '^(?:https?://)?([^/]+)', 1)) AS url_domain_len,
    length(regexp_replace(wp.wp_url, '^(?:https?://)?[^/]+/', '')) AS url_path_len,
    concat(CAST(ws.ws_sales_price AS VARCHAR), ' USD') AS sales_price_str,
    round(ws.ws_ext_discount_amt / nullif(ws.ws_ext_sales_price, 0), 4) AS discount_rate,
    case when regexp_like(c.c_email_address, '^.*@gmail\\.com$') then 'Gmail' else 'Other' end AS email_provider,
    sum(ss.ss_net_profit) AS total_store_net_profit,
    sum(ws.ws_net_profit) AS total_web_net_profit,
    count(*) AS transaction_count
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN web_sales ws ON ss.ss_sold_date_sk = ws.ws_sold_date_sk AND ss.ss_item_sk = ws.ws_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN call_center cc ON s.s_market_id = cc.cc_mkt_id
WHERE d.d_year = 2002
  AND regexp_like(i.i_item_desc, '.*[A-Z]{3}.*')
GROUP BY
    lower(split_part(c.c_email_address, '@', 2)),
    regexp_extract(c.c_email_address, '\\.([A-Za-z]+)$', 1),
    lower(c.c_login),
    concat_ws(' ', c.c_first_name, c.c_last_name),
    length(concat_ws(' ', c.c_first_name, c.c_last_name)),
    lower(trim(p.p_promo_name)),
    length(p.p_promo_name),
    concat_ws(' - ', s.s_store_name, s.s_city, s.s_state),
    length(s.s_store_name),
    substr(s.s_store_name, 1, 3),
    upper(regexp_replace(cc.cc_name, '\\b(\\w)\\w*\\b', '\\1')),
    replace(cc.cc_hours, '-', ' to '),
    concat_ws(', ', s.s_city, s.s_state, s.s_zip),
    lower(i.i_product_name),
    lower(i.i_color),
    lower(i.i_size),
    regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', ''),
    length(regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '')),
    lower(wp.wp_url),
    regexp_extract(wp.wp_url, '^(?:https?://)?([^/]+)', 1),
    length(regexp_extract(wp.wp_url, '^(?:https?://)?([^/]+)', 1)),
    length(regexp_replace(wp.wp_url, '^(?:https?://)?[^/]+/', '')),
    concat(CAST(ws.ws_sales_price AS VARCHAR), ' USD'),
    round(ws.ws_ext_discount_amt / nullif(ws.ws_ext_sales_price, 0), 4),
    case when regexp_like(c.c_email_address, '^.*@gmail\\.com$') then 'Gmail' else 'Other' end
ORDER BY total_store_net_profit DESC
LIMIT 100
