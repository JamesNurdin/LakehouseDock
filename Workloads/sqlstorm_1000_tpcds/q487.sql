WITH sales_strings AS (
    SELECT
        d.d_year AS d_year,
        s.s_store_id AS store_id,
        s.s_city AS store_city,
        c.c_customer_id AS cust_id,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        p.p_promo_name AS promo_name,
        p.p_channel_dmail,
        p.p_channel_email,
        p.p_channel_catalog,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_press,
        p.p_channel_event,
        concat_ws('|',
            c.c_customer_id,
            s.s_store_id,
            i.i_item_id,
            coalesce(p.p_promo_name, ''),
            coalesce(p.p_channel_dmail, ''),
            coalesce(p.p_channel_email, ''),
            coalesce(p.p_channel_catalog, ''),
            coalesce(p.p_channel_tv, ''),
            coalesce(p.p_channel_radio, ''),
            coalesce(p.p_channel_press, ''),
            coalesce(p.p_channel_event, '')
        ) AS raw_concat,
        regexp_replace(
            lower(concat_ws(' ', c.c_first_name, c.c_last_name, s.s_city, i.i_product_name, coalesce(p.p_promo_name, ''))),
            '[^a-z0-9]', ''
        ) AS cleaned_concat,
        length(
            regexp_replace(
                lower(concat_ws(' ', c.c_first_name, c.c_last_name, s.s_city, i.i_product_name, coalesce(p.p_promo_name, ''))),
                '[^a-z0-9]', ''
            )
        ) AS cleaned_len,
        cardinality(split(regexp_replace(lower(i.i_product_name), '[^a-z0-9 ]', ''), ' ')) AS product_word_count,
        ss.ss_net_paid,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 1999
      AND s.s_state = 'TX'
      AND i.i_color IN ('Red','Blue')
)
SELECT
    d_year,
    substr(cleaned_concat, 1, 10) AS prefix,
    cleaned_len,
    product_word_count,
    sum(ss_net_paid) AS total_net_paid,
    sum(ss_quantity) AS total_quantity,
    count(*) AS txn_count,
    approx_distinct(raw_concat) AS distinct_raw_strings,
    max(regexp_extract(substr(cleaned_concat, 1, 10), '([a-z0-9]+)', 1)) AS extracted_prefix,
    max(reverse(substr(cleaned_concat, 1, 10))) AS rev_prefix,
    max(translate(substr(cleaned_concat, 1, 10), 'aeiou', '12345')) AS translated_prefix,
    max(replace(substr(cleaned_concat, 1, 10), 'a', '@')) AS replaced_a,
    max(array_join(split(substr(cleaned_concat, 1, 10), ''), '-')) AS chars_joined
FROM sales_strings
GROUP BY
    d_year,
    substr(cleaned_concat, 1, 10),
    cleaned_len,
    product_word_count
ORDER BY total_net_paid DESC
LIMIT 100
