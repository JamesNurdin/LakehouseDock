WITH sales_strings AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        i.i_item_id,
        i.i_product_name,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_address_sk,
        concat_ws('_',
            lower(regexp_replace(c.c_first_name, '\\s+', '')),
            lower(regexp_replace(c.c_last_name, '\\s+', '')),
            substr(i.i_product_name, 1, 10),
            replace(i.i_color, ' ', ''),
            replace(i.i_size, ' ', '')
        ) AS raw_concat,
        regexp_replace(concat_ws('_',
            lower(regexp_replace(c.c_first_name, '\\s+', '')),
            lower(regexp_replace(c.c_last_name, '\\s+', '')),
            substr(i.i_product_name, 1, 10),
            replace(i.i_color, ' ', ''),
            replace(i.i_size, ' ', '')
        ), '[^a-z0-9_]', '') AS clean_concat,
        length(concat_ws('_',
            lower(regexp_replace(c.c_first_name, '\\s+', '')),
            lower(regexp_replace(c.c_last_name, '\\s+', '')),
            substr(i.i_product_name, 1, 10),
            replace(i.i_color, ' ', ''),
            replace(i.i_size, ' ', '')
        )) AS concat_len,
        regexp_extract(i.i_product_name, '(\\d{4})', 1) AS prod_year,
        element_at(split(i.i_product_name, '\\s+'), 1) AS first_word,
        array_join(split(i.i_product_name, '\\s+'), '-') AS hyphenated_name,
        regexp_count(i.i_product_name, '[AEIOUaeiou]') AS vowel_count,
        strpos(i.i_product_name, ' ') AS first_space_pos,
        trim(i.i_product_name) AS trimmed_product_name,
        replace(i.i_product_name, ' ', '_') AS spaced_to_underscore,
        cardinality(split(i.i_product_name, '\\s+')) AS product_name_word_count
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE
        d.d_year BETWEEN 1999 AND 2000
        AND regexp_like(i.i_product_name, '\\b[A-Z]{2}[0-9]{4}\\b')
)
SELECT
    d_year,
    d_month_seq,
    s_store_id,
    COUNT(DISTINCT ss_ticket_number) AS txn_cnt,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(concat_len) AS avg_concat_len,
    MIN(concat_len) AS min_concat_len,
    MAX(concat_len) AS max_concat_len,
    COUNT_IF(regexp_like(clean_concat, '^a')) AS cnt_clean_start_a,
    COUNT_IF(regexp_like(prod_year, '^199[5-9]')) AS cnt_prod_year_1995_1999,
    COUNT(DISTINCT clean_concat) AS distinct_clean_concat,
    AVG(vowel_count) AS avg_vowel_cnt,
    COUNT_IF(regexp_like(i_product_name, '\\b\\w{3}\\d{2}\\w\\b')) AS cnt_pattern_xyz,
    COUNT(DISTINCT hyphenated_name) AS distinct_hyphenated_name,
    COUNT(DISTINCT first_word) AS distinct_first_word,
    AVG(product_name_word_count) AS avg_word_cnt,
    AVG(first_space_pos) AS avg_first_space_pos,
    COUNT_IF(regexp_like(spaced_to_underscore, '^.*_.*_.*$')) AS cnt_multi_underscore,
    SUM(length(trimmed_product_name) - length(replace(trimmed_product_name, ' ', ''))) AS total_spaces_in_names
FROM
    sales_strings
GROUP BY
    d_year,
    d_month_seq,
    s_store_id
ORDER BY
    d_year,
    d_month_seq,
    s_store_id
