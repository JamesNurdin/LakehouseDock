WITH
customer_norm AS (
    SELECT
        c.c_customer_sk,
        lower(trim(c.c_email_address)) AS email_norm,
        regexp_extract(lower(c.c_email_address), '@([^\\.]+\\..+)', 1) AS email_domain,
        lower(regexp_replace(c.c_login, '\\s+', '')) AS login_clean,
        concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
        length(c.c_email_address) AS email_len,
        length(c.c_first_name) + length(c.c_last_name) AS name_len
    FROM customer c
),
item_norm AS (
    SELECT
        i.i_item_sk,
        lower(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')) AS clean_desc,
        length(i.i_item_desc) AS desc_len,
        cardinality(split(i.i_item_desc, '\\s+')) AS word_count,
        substr(i.i_product_name, 1, 10) AS prod_name_prefix,
        concat_ws('_', lower(i.i_color), lower(i.i_size)) AS color_size_key
    FROM item i
),
store_norm AS (
    SELECT
        s.s_store_sk,
        concat_ws(' ', s.s_street_number, s.s_street_name, s.s_city, s.s_state, s.s_zip) AS raw_address,
        lower(regexp_replace(concat_ws(' ', s.s_street_number, s.s_street_name, s.s_city, s.s_state, s.s_zip), '\\s+', '')) AS address_norm,
        s.s_hours AS store_hours,
        length(s.s_hours) AS hours_len
    FROM store s
),
sales_enriched AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_month_seq AS month_id,
        d.d_date,
        cn.email_norm,
        cn.email_domain,
        cn.login_clean,
        cn.full_name,
        cn.email_len,
        cn.name_len,
        inr.clean_desc,
        inr.desc_len,
        inr.word_count,
        inr.prod_name_prefix,
        inr.color_size_key,
        sn.raw_address,
        sn.address_norm,
        ss.ss_quantity AS quantity,
        ss.ss_sales_price AS sales_price,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_norm cn ON ss.ss_customer_sk = cn.c_customer_sk
    JOIN item_norm inr ON ss.ss_item_sk = inr.i_item_sk
    JOIN store_norm sn ON ss.ss_store_sk = sn.s_store_sk
)
SELECT
    d_year,
    month_id,
    sum(sales_price) AS total_sales_price,
    sum(quantity) AS total_quantity,
    sum(net_paid) AS total_net_paid,
    count(DISTINCT email_domain) AS distinct_email_domains,
    array_join(array_sort(array_agg(DISTINCT email_domain)), ', ') AS email_domains_sorted,
    avg(word_count) AS avg_desc_word_count,
    max(desc_len) AS max_desc_len,
    length(array_join(array_agg(DISTINCT address_norm), '|')) AS total_address_norm_length,
    cardinality(array_distinct(array_agg(color_size_key))) AS distinct_color_size_keys,
    array_join(array_sort(array_distinct(array_agg(color_size_key))), ', ') AS color_size_keys_sorted,
    concat_ws(' | ',
        substr(array_join(array_agg(DISTINCT clean_desc), ' '), 1, 100),
        substr(array_join(array_agg(DISTINCT prod_name_prefix), ','), 1, 50)
    ) AS sample_desc_and_prefix
FROM sales_enriched
GROUP BY d_year, month_id
ORDER BY d_year, month_id
