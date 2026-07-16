SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    d.d_date,
    concat_ws(' | ',
        lower(trim(s.s_store_name)),
        replace(lower(i.i_product_name), ' ', '_'),
        regexp_replace(cc.cc_hours, '[^0-9]', ''),
        substring(upper(s.s_state), 1, 2),
        regexp_extract(c.c_email_address, '@([^.]*)', 1)
    ) AS combined_string,
    length(concat_ws(' ', s.s_store_name, i.i_product_name, c.c_first_name, c.c_last_name)) AS total_len,
    reverse(s.s_store_name) AS reversed_store_name,
    CASE WHEN regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN 'valid' ELSE 'invalid' END AS email_status,
    translate(cc.cc_name, 'AEIOUaeiou', '**********') AS masked_cc_name,
    format('NetPaid: %.2f', ss.ss_net_paid) AS net_paid_formatted,
    replace(lower(i.i_product_name), ' ', '-') AS product_slug,
    array_join(split(i.i_product_name, ' '), '|') AS product_words_joined,
    concat(substring(lower(c.c_first_name), 1, 1), reverse(lower(c.c_last_name))) AS name_code,
    repeat(upper(p.p_promo_name), 2) AS promo_name_repeated,
    regexp_replace(regexp_replace(cc.cc_hours, '\\s+', ''), '\\D', '') AS hours_digits,
    concat_ws(' ', s.s_street_number, s.s_street_name, s.s_street_type) AS store_full_address,
    cardinality(split(i.i_product_name, ' ')) AS product_word_count
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN call_center cc ON s.s_market_id = cc.cc_mkt_id
WHERE ss.ss_net_paid > 0
  AND regexp_like(c.c_email_address, '@')
