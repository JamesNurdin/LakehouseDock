WITH
customer_parsed AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_email_address,
        split_part(c_email_address, '@', 1) AS email_user,
        split_part(c_email_address, '@', 2) AS email_domain,
        lower(split_part(c_email_address, '@', 1)) AS email_user_lc,
        length(c_email_address) AS email_len,
        regexp_replace(c_first_name, '[AEIOUaeiou]', '*') AS first_name_masked,
        regexp_replace(c_last_name, '[AEIOUaeiou]', '*') AS last_name_masked
    FROM customer
),
item_processed AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_product_name,
        i_item_desc,
        lower(i_item_desc) AS desc_lower,
        regexp_replace(i_item_desc, '[^a-zA-Z0-9 ]', '') AS desc_alnum,
        cardinality(split(regexp_replace(i_item_desc, '[^a-zA-Z0-9 ]', ' '), ' ')) AS word_count,
        regexp_replace(lower(i_item_desc), '\\s+', ' ') AS desc_normalized
    FROM item
),
call_center_processed AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        lower(cc_name) AS cc_name_lc,
        replace(cc_name, ' ', '_') AS cc_name_underscored,
        length(cc_name) AS cc_name_len
    FROM call_center
),
sales_augmented AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_year,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cp.cp_description,
        i.desc_alnum,
        i.word_count,
        i.desc_normalized,
        cc.cc_name_underscored,
        c.email_user_lc,
        c.email_domain,
        concat_ws(' ', c.email_user_lc, cc.cc_name_underscored, i.desc_alnum) AS composite_key,
        length(concat_ws(' ', c.email_user_lc, cc.cc_name_underscored, i.desc_alnum)) AS composite_len,
        regexp_like(i.desc_alnum, '[0-9]{2,}') AS contains_digits,
        substr(i.desc_alnum, 1, 20) AS desc_prefix,
        replace(i.desc_alnum, ' ', '-') AS desc_hyphenated,
        regexp_replace(c.first_name_masked || ' ' || c.last_name_masked, '\\s+', '') AS masked_name_concat
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_parsed c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item_processed i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center_processed cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
)
SELECT
    d_year,
    count(*) AS total_orders,
    sum(cs_net_paid) AS sum_net_paid,
    sum(cs_net_profit) AS sum_net_profit,
    avg(composite_len) AS avg_composite_len,
    max(composite_len) AS max_composite_len,
    min(composite_len) AS min_composite_len,
    sum(CASE WHEN contains_digits THEN 1 ELSE 0 END) AS orders_with_digits,
    approx_percentile(composite_len, 0.5) AS median_composite_len,
    upper(max(composite_key)) AS max_composite_key_upper,
    replace(lower(min(composite_key)), ' ', '_') AS min_composite_key_underscored,
    substr(max(composite_key), 1, 30) AS max_composite_key_prefix,
    regexp_replace(max(composite_key), '[^A-Z0-9_]', '') AS cleaned_max_key,
    count(distinct email_domain) AS distinct_email_domains,
    sum(word_count) AS total_desc_word_count
FROM sales_augmented
GROUP BY d_year
ORDER BY sum_net_paid DESC
LIMIT 10
