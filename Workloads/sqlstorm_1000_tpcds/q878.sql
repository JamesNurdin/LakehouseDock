WITH
web_sales_pre AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
page_url_parts AS (
    SELECT
        wp.wp_web_page_sk,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        lower(regexp_replace(wp.wp_url, '(?i)[^a-z0-9]', '')) AS cleaned_url
    FROM web_page wp
),
promotion_channels AS (
    SELECT
        p.p_promo_sk,
        concat_ws('_',
            CASE WHEN p.p_channel_dmail = 'Y' THEN 'DM' ELSE '' END,
            CASE WHEN p.p_channel_email = 'Y' THEN 'EM' ELSE '' END,
            CASE WHEN p.p_channel_catalog = 'Y' THEN 'CAT' ELSE '' END,
            CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE '' END,
            CASE WHEN p.p_channel_radio = 'Y' THEN 'RAD' ELSE '' END,
            CASE WHEN p.p_channel_press = 'Y' THEN 'PRS' ELSE '' END,
            CASE WHEN p.p_channel_event = 'Y' THEN 'EVT' ELSE '' END,
            CASE WHEN p.p_channel_demo = 'Y' THEN 'DEM' ELSE '' END
        ) AS channels,
        lower(regexp_replace(p.p_promo_name, '(?i)[^a-z0-9]', '')) AS norm_promo_name
    FROM promotion p
),
item_features AS (
    SELECT
        i.i_item_sk,
        lower(regexp_replace(i.i_item_desc, '(?i)[^a-z0-9]', '')) AS norm_desc,
        lower(regexp_replace(i.i_product_name, '(?i)[^a-z0-9]', '')) AS norm_prod_name,
        length(i.i_item_desc) AS desc_len,
        length(i.i_product_name) AS prod_name_len,
        regexp_count(lower(i.i_item_desc), '(?i)eco') AS eco_count_desc,
        regexp_count(lower(i.i_product_name), '(?i)eco') AS eco_count_prod
    FROM item i
),
customer_emails AS (
    SELECT
        c.c_customer_sk,
        regexp_extract(c.c_email_address, '@([^\\.]+)\\.', 1) AS email_domain,
        lower(regexp_replace(c.c_first_name || c.c_last_name, '(?i)[^a-z0-9]', '')) AS norm_full_name
    FROM customer c
)
SELECT
    d.d_month_seq AS month_seq,
    pu.channels,
    pu.norm_promo_name,
    pa.domain,
    pa.cleaned_url,
    ce.email_domain,
    if_feat.norm_desc,
    if_feat.norm_prod_name,
    substring(pa.domain, 1, 3) AS domain_prefix,
    reverse(ce.email_domain) AS rev_email_domain,
    replace(pa.cleaned_url, 'www', '') AS url_without_www,
    length(pa.cleaned_url) AS cleaned_url_len,
    strpos(pa.cleaned_url, 'shop') AS shop_position,
    substring(if_feat.norm_prod_name, 1, 5) AS prod_name_prefix,
    sum(wsp.ws_net_paid) AS total_net_paid,
    sum(wsp.ws_quantity) AS total_quantity,
    avg(if_feat.desc_len) AS avg_desc_len,
    avg(if_feat.prod_name_len) AS avg_prod_name_len,
    sum(if_feat.eco_count_desc + if_feat.eco_count_prod) AS total_eco_occurrences,
    count(DISTINCT wsp.ws_order_number) AS distinct_orders,
    approx_percentile(wsp.ws_net_paid, 0.5) AS median_net_paid
FROM web_sales_pre wsp
JOIN date_dim d ON wsp.ws_sold_date_sk = d.d_date_sk
JOIN page_url_parts pa ON wsp.ws_web_page_sk = pa.wp_web_page_sk
JOIN promotion_channels pu ON wsp.ws_promo_sk = pu.p_promo_sk
JOIN item_features if_feat ON wsp.ws_item_sk = if_feat.i_item_sk
JOIN customer_emails ce ON wsp.ws_bill_customer_sk = ce.c_customer_sk
JOIN web_returns wr ON wsp.ws_order_number = wr.wr_order_number
WHERE d.d_year = 2001
GROUP BY
    d.d_month_seq,
    pu.channels,
    pu.norm_promo_name,
    pa.domain,
    pa.cleaned_url,
    ce.email_domain,
    if_feat.norm_desc,
    if_feat.norm_prod_name,
    substring(pa.domain, 1, 3),
    reverse(ce.email_domain),
    replace(pa.cleaned_url, 'www', ''),
    length(pa.cleaned_url),
    strpos(pa.cleaned_url, 'shop'),
    substring(if_feat.norm_prod_name, 1, 5)
HAVING sum(wsp.ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
