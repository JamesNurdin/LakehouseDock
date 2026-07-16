SELECT
    c.c_customer_id,
    lower(c.c_email_address) AS email_lower,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    length(element_at(split(c.c_email_address, '@'), 1)) AS email_local_len,
    wp.wp_url,
    lower(regexp_replace(wp.wp_url, '^https?://', '')) AS normalized_url,
    element_at(split(regexp_replace(wp.wp_url, '^https?://', ''), '/'), 1) AS url_domain,
    cardinality(split(regexp_replace(wp.wp_url, '^https?://[^/]+', ''), '/')) AS url_path_segments,
    i.i_product_name,
    lower(i.i_product_name) AS product_name_lower,
    reverse(i.i_product_name) AS product_name_rev,
    length(regexp_replace(i.i_product_name, '[^AEIOUaeiou]', '')) AS vowel_count,
    substring(i.i_product_name, 1, 5) AS product_name_prefix,
    concat(
        c.c_customer_id, '-',
        substring(regexp_extract(c.c_email_address, '@(.+)$', 1), 1, 3), '-',
        substring(element_at(split(regexp_replace(wp.wp_url, '^https?://', ''), '/'), 1), 1, 3)
    ) AS composite_key,
    sum(ws.ws_net_paid) AS total_net_paid,
    sum(ws.ws_ext_sales_price) AS total_ext_sales,
    count(*) AS sales_cnt,
    min(d.d_date) AS first_sale_date,
    max(d.d_date) AS last_sale_date
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE c.c_email_address IS NOT NULL
  AND wp.wp_url IS NOT NULL
GROUP BY
    c.c_customer_id,
    lower(c.c_email_address),
    regexp_extract(c.c_email_address, '@(.+)$', 1),
    length(element_at(split(c.c_email_address, '@'), 1)),
    wp.wp_url,
    lower(regexp_replace(wp.wp_url, '^https?://', '')),
    element_at(split(regexp_replace(wp.wp_url, '^https?://', ''), '/'), 1),
    cardinality(split(regexp_replace(wp.wp_url, '^https?://[^/]+', ''), '/')),
    i.i_product_name,
    lower(i.i_product_name),
    reverse(i.i_product_name),
    length(regexp_replace(i.i_product_name, '[^AEIOUaeiou]', '')),
    substring(i.i_product_name, 1, 5),
    concat(
        c.c_customer_id, '-',
        substring(regexp_extract(c.c_email_address, '@(.+)$', 1), 1, 3), '-',
        substring(element_at(split(regexp_replace(wp.wp_url, '^https?://', ''), '/'), 1), 1, 3)
    )
ORDER BY total_net_paid DESC
LIMIT 100
