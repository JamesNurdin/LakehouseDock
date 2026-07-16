WITH
store_sales_clean AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_net_profit,
        lower(regexp_replace(i.i_product_name, '[^a-zA-Z0-9]', '_')) AS clean_product_name,
        replace(i.i_color, ' ', '') AS color_no_space,
        length(i.i_product_name) AS product_name_len,
        substr(i.i_product_name, 1, 10) AS product_name_prefix,
        lower(concat_ws('-', s.s_city, s.s_state)) AS location_lower,
        reverse(lower(concat_ws('_', s.s_store_name, cast(s.s_store_sk AS varchar)))) AS reversed_store_id,
        concat_ws('|', lower(s.s_store_name), cast(d.d_year AS varchar), cast(d.d_month_seq AS varchar)) AS grouping_key
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE s.s_country = 'United States'
),
web_sales_clean AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_net_profit,
        lower(regexp_replace(i.i_product_name, '[^a-zA-Z0-9]', '_')) AS clean_product_name,
        split_part(wp.wp_url, '/', 3) AS url_domain,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS extracted_host,
        lower(wp.wp_type) AS wp_type_lower,
        concat_ws('#', lower(wp.wp_type), cast(d.d_year AS varchar), cast(d.d_month_seq AS varchar)) AS web_group_key
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE wp.wp_url IS NOT NULL
),
email_domains AS (
    SELECT
        c.c_customer_sk,
        lower(regexp_replace(c.c_email_address, '\\s+', '')) AS email_clean,
        CASE
            WHEN strpos(c.c_email_address, '@') > 0 THEN lower(substr(c.c_email_address, strpos(c.c_email_address, '@') + 1))
            ELSE NULL
        END AS email_domain
    FROM customer c
    WHERE c.c_email_address IS NOT NULL
),
combined AS (
    SELECT
        'store' AS sales_channel,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_store_sk AS store_sk,
        CAST(NULL AS integer) AS web_page_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_net_profit AS net_profit,
        ss.clean_product_name,
        CAST(NULL AS varchar) AS url_domain,
        ss.grouping_key AS channel_key,
        ed.email_domain
    FROM store_sales_clean ss
    LEFT JOIN email_domains ed ON ss.ss_customer_sk = ed.c_customer_sk

    UNION ALL

    SELECT
        'web' AS sales_channel,
        ws.ws_sold_date_sk AS sold_date_sk,
        CAST(NULL AS integer) AS store_sk,
        ws.ws_web_page_sk AS web_page_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_net_profit AS net_profit,
        ws.clean_product_name,
        ws.url_domain,
        ws.web_group_key AS channel_key,
        ed.email_domain
    FROM web_sales_clean ws
    LEFT JOIN email_domains ed ON ws.ws_bill_customer_sk = ed.c_customer_sk
)
SELECT
    sales_channel,
    channel_key,
    COUNT(DISTINCT customer_sk) AS distinct_customers,
    SUM(net_profit) AS total_net_profit,
    array_join(array_agg(DISTINCT clean_product_name), ',') AS product_list,
    COUNT(DISTINCT email_domain) AS distinct_email_domains,
    MAX(email_domain) FILTER (WHERE email_domain IS NOT NULL) AS max_email_domain,
    SUM(LENGTH(clean_product_name)) AS total_clean_name_len,
    AVG(LENGTH(url_domain)) FILTER (WHERE url_domain IS NOT NULL) AS avg_url_domain_len,
    MAX(CAST(regexp_extract(channel_key, '\\d+$', 0) AS integer)) AS max_month_seq
FROM combined
WHERE channel_key IS NOT NULL
GROUP BY sales_channel, channel_key
HAVING SUM(net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 200
