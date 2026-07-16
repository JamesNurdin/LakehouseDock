WITH
norm_item AS (
    SELECT
        i_item_sk,
        i_brand,
        i_color,
        i_size,
        i_product_name,
        i_item_desc,
        lower(regexp_replace(i_item_desc, '[^a-z0-9]+', ' ')) AS cleaned_desc,
        length(i_item_desc) AS desc_len,
        substring(i_product_name, 1, 15) AS product_name_prefix,
        concat(i_brand, '-', i_color, '-', i_size) AS product_code,
        reverse(concat(i_brand, '-', i_color, '-', i_size)) AS rev_product_code,
        concat('PID-', CAST(i_item_sk AS varchar), '-', concat(i_brand, '-', i_color, '-', i_size)) AS extended_product_id,
        replace(substring(i_product_name, 1, 15), '-', '_') AS prod_name_sanitized,
        array_join(slice(split(lower(regexp_replace(i_item_desc, '[^a-z0-9]+', ' ')), ' '), 1, 3), ' ') AS desc_first_three_words
    FROM item
),
norm_customer AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        lower(regexp_replace(concat(c_first_name, ' ', c_last_name), '\\s+', '_')) AS normalized_name,
        length(concat(c_first_name, c_last_name)) AS name_len,
        reverse(lower(regexp_replace(concat(c_first_name, ' ', c_last_name), '\\s+', '_'))) AS rev_norm_name,
        concat(substring(c_first_name, 1, 1), substring(c_last_name, 1, 1)) AS name_initials
    FROM customer
),
sales_str AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ni.cleaned_desc,
        ni.desc_len,
        ni.product_code,
        ni.rev_product_code,
        ni.extended_product_id,
        ni.prod_name_sanitized,
        ni.desc_first_three_words,
        nc.normalized_name,
        nc.rev_norm_name,
        nc.name_initials,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM store_sales ss
    JOIN norm_item ni ON ss.ss_item_sk = ni.i_item_sk
    JOIN norm_customer nc ON ss.ss_customer_sk = nc.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(ni.cleaned_desc, '.*[aeiou]{3}.*')
)
SELECT
    d_year,
    d_month_seq,
    substring(d_day_name, 1, 3) AS day_abbrev,
    product_code,
    count(*) AS sales_cnt,
    sum(ss_net_paid) AS total_paid,
    sum(ss_net_profit) AS total_profit,
    avg(desc_len) AS avg_desc_len,
    approx_distinct(normalized_name) AS distinct_customers,
    array_join(array_agg(DISTINCT prod_name_sanitized), '|') AS product_names_sanitized,
    max(rev_product_code) AS sample_rev_product_code,
    min(extended_product_id) AS sample_extended_product_id,
    max(desc_first_three_words) AS sample_desc_prefix
FROM sales_str
GROUP BY
    d_year,
    d_month_seq,
    substring(d_day_name, 1, 3),
    product_code
HAVING sum(ss_net_paid) > 1000
ORDER BY total_paid DESC
LIMIT 100
