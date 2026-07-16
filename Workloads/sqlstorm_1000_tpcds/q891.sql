WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_net_paid,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        s.s_hours,
        i.i_product_name,
        i.i_item_desc,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        p.p_promo_name
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
),
processed AS (
    SELECT
        date_sk,
        ss_net_paid,
        lower(regexp_replace(s_store_name, '[^a-zA-Z0-9 ]', '')) AS clean_store_name,
        concat_ws(', ', s_city, s_state) AS city_state,
        replace(s_hours, ':', '-') AS normalized_hours,
        regexp_replace(i_product_name, '\\s+', ' ') AS normalized_product_name,
        lower(split(c_email_address, '@')[2]) AS email_domain,
        concat(
            upper(substr(c_first_name, 1, 1)), lower(substr(c_first_name, 2)),
            ' ',
            upper(substr(c_last_name, 1, 1)), lower(substr(c_last_name, 2))
        ) AS proper_name,
        format('%s-%s-%s', s_city, s_state, s_country) AS location_code,
        lower(regexp_replace(p_promo_name, '[^\\w]', '')) AS promo_name_clean,
        length(i_item_desc) AS desc_len,
        cardinality(split(i_item_desc, ' ')) AS desc_word_count,
        length(regexp_replace(i_item_desc, '[^[:alnum:]]', '')) AS clean_desc_len
    FROM sales_data
    WHERE ss_net_paid IS NOT NULL
)
SELECT
    location_code,
    email_domain,
    clean_store_name,
    proper_name,
    promo_name_clean,
    sum(ss_net_paid) AS total_net_paid,
    avg(desc_len) AS avg_desc_len,
    avg(desc_word_count) AS avg_desc_word_count,
    sum(clean_desc_len) AS total_clean_desc_len,
    count(*) AS sales_count
FROM processed
GROUP BY
    location_code,
    email_domain,
    clean_store_name,
    proper_name,
    promo_name_clean
ORDER BY total_net_paid DESC
LIMIT 100
