WITH processed AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_date,
        date_format(d.d_date, '%Y-%m') AS month_key,
        s.s_store_name,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        c.c_email_address,
        lower(trim(c.c_first_name)) AS first_name_lc,
        upper(trim(c.c_last_name)) AS last_name_uc,
        regexp_replace(regexp_extract(c.c_email_address, '@([^@]+)', 1), '[0-9]', '') AS email_domain_alpha,
        concat_ws('_', lower(trim(c.c_first_name)), upper(trim(c.c_last_name)), regexp_replace(regexp_extract(c.c_email_address, '@([^@]+)', 1), '[0-9]', '')) AS cust_key,
        concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS full_name,
        i.i_product_name,
        i.i_item_desc,
        lower(i.i_product_name) AS product_name_lc,
        regexp_replace(i.i_item_desc, '[^A-Za-z ]', '') AS clean_desc,
        cardinality(split(regexp_replace(i.i_item_desc, '[^A-Za-z ]', ''), ' ')) AS desc_word_count,
        length(i.i_item_desc) AS desc_len,
        substring(i.i_product_name, 1, 5) AS product_name_prefix,
        replace(i.i_product_name, ' ', '_') AS product_name_underscore,
        regexp_replace(i.i_product_name, '[AEIOUaeiou]', '') AS product_name_no_vowels,
        array_join(regexp_extract_all(i.i_product_name, '\\w+'), '|') AS product_name_words_pipe
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
)
SELECT
    s_store_name,
    month_key,
    cust_key,
    full_name,
    email_domain_alpha,
    COUNT(*) AS txn_cnt,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_profit,
    AVG(desc_word_count) AS avg_item_desc_word_cnt,
    MIN(desc_len) AS min_item_desc_len,
    MAX(desc_len) AS max_item_desc_len,
    array_join(array_agg(DISTINCT product_name_lc), ', ') AS product_names_lc,
    array_join(array_agg(DISTINCT product_name_prefix), ', ') AS product_name_prefixes,
    array_join(array_agg(DISTINCT product_name_underscore), ', ') AS product_name_underscores,
    array_join(array_agg(DISTINCT product_name_no_vowels), ', ') AS product_name_no_vowels,
    array_join(array_agg(DISTINCT product_name_words_pipe), ', ') AS product_name_word_pipes
FROM processed
GROUP BY
    s_store_name,
    month_key,
    cust_key,
    full_name,
    email_domain_alpha
HAVING COUNT(*) > 5
ORDER BY total_net_paid DESC
LIMIT 100
