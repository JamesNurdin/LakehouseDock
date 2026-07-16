WITH page_details AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        lower(wp.wp_url) AS url_lower,
        regexp_extract(wp.wp_url, '^(?:https?://)?([^/]+)', 1) AS domain,
        length(wp.wp_url) AS url_len,
        regexp_replace(wp.wp_url, '[^A-Za-z0-9]', '') AS sanitized_url,
        split(wp.wp_url, '/') AS url_parts,
        cardinality(split(wp.wp_url, '/')) AS url_part_cnt,
        wp.wp_type
    FROM web_page wp
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        length(i.i_item_desc) AS item_desc_len,
        cardinality(split(i.i_item_desc, ' ')) AS item_desc_word_cnt,
        regexp_replace(i.i_item_desc, '[^A-Za-z ]', ' ') AS cleaned_desc,
        replace(i.i_color, ' ', '-') AS color_dash,
        substr(i.i_product_name, 1, 10) AS prod_name_prefix
    FROM item i
),
promo_details AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        lower(p.p_promo_name) AS promo_name_lower,
        regexp_replace(p.p_promo_name, '\\s+', '_') AS promo_name_underscore,
        lower(p.p_discount_active) AS discount_active_lower
    FROM promotion p
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        lower(c.c_email_address) AS email_lower,
        regexp_extract(c.c_email_address, '@([^\\.]+)', 1) AS email_domain,
        concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
        upper(concat_ws(' ', c.c_first_name, c.c_last_name)) AS full_name_upper
    FROM customer c
),
joined_sales AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        i_det.i_brand,
        i_det.item_desc_len,
        i_det.item_desc_word_cnt,
        i_det.prod_name_prefix,
        i_det.color_dash,
        p_det.promo_name_underscore,
        p_det.discount_active_lower,
        pg_det.domain,
        pg_det.url_len,
        pg_det.sanitized_url,
        pg_det.wp_type,
        c_det.email_domain,
        c_det.full_name_upper,
        wsit.web_state
    FROM web_sales ws
    LEFT JOIN item_details i_det ON ws.ws_item_sk = i_det.i_item_sk
    LEFT JOIN promo_details p_det ON ws.ws_promo_sk = p_det.p_promo_sk
    LEFT JOIN page_details pg_det ON ws.ws_web_page_sk = pg_det.wp_web_page_sk
    LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN customer_details c_det ON ws.ws_bill_customer_sk = c_det.c_customer_sk
    WHERE pg_det.domain IS NOT NULL
),
composite AS (
    SELECT
        order_number,
        quantity,
        net_paid,
        net_profit,
        url_len,
        item_desc_len,
        item_desc_word_cnt,
        prod_name_prefix,
        color_dash,
        domain,
        wp_type,
        email_domain,
        full_name_upper,
        web_state,
        discount_active_lower,
        concat_ws('_',
            lower(i_brand),
            promo_name_underscore,
            lower(domain),
            lower(email_domain),
            lower(web_state),
            CASE WHEN discount_active_lower = 'yes' THEN 'discount' ELSE 'regular' END
        ) AS composite_key
    FROM joined_sales
)
SELECT
    composite_key,
    count(DISTINCT order_number) AS orders,
    sum(quantity) AS total_quantity,
    sum(net_paid) AS total_net_paid,
    sum(net_profit) AS total_net_profit,
    avg(url_len) AS avg_url_length,
    avg(item_desc_len) AS avg_item_desc_length,
    avg(item_desc_word_cnt) AS avg_item_desc_word_cnt,
    min(prod_name_prefix) AS min_product_name_prefix,
    max(color_dash) AS max_color_dash,
    length(composite_key) AS composite_key_length,
    regexp_replace(composite_key, '([a-z])([A-Z])', '\\1_\\2') AS snake_case_key
FROM composite
GROUP BY composite_key
ORDER BY total_net_paid DESC
LIMIT 100
