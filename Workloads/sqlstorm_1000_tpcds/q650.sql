WITH
customer_strings AS (
    SELECT
        c_customer_sk,
        lower(trim(c_first_name)) AS first_name_lower,
        upper(trim(c_last_name)) AS last_name_upper,
        concat(lower(trim(c_first_name)), ' ', upper(trim(c_last_name))) AS full_name_mixed,
        regexp_replace(c_email_address, '[^a-zA-Z0-9@.]', '') AS clean_email,
        substr(c_login, 1, 5) AS login_prefix
    FROM customer
),
item_strings AS (
    SELECT
        i_item_sk,
        lower(i_item_desc) AS item_desc_lower,
        regexp_replace(i_product_name, '\\s+', '_') AS product_name_underscored,
        length(i_item_desc) AS item_desc_len,
        cardinality(split(i_item_desc, ' ')) AS item_desc_word_cnt,
        substr(i_item_desc, 1, 10) AS item_desc_prefix,
        reverse(i_item_id) AS reversed_item_id,
        regexp_extract(i_item_desc, '(\\d+)', 1) AS first_number_in_desc
    FROM item
),
call_center_strings AS (
    SELECT
        cc_call_center_sk,
        lower(cc_name) AS cc_name_lower,
        replace(cc_manager, ' ', '_') AS manager_underscored,
        regexp_like(cc_hours, '^([0-9]{2}:[0-9]{2})(-[0-9]{2}:[0-9]{2})?$') AS hours_match_pattern,
        concat(cc_city, ',', cc_state) AS city_state
    FROM call_center
),
sales_join AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_year,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cstr.first_name_lower,
        cstr.last_name_upper,
        cstr.full_name_mixed,
        cstr.clean_email,
        cstr.login_prefix,
        istr.item_desc_len,
        istr.item_desc_word_cnt,
        istr.reversed_item_id,
        ccs.cc_name_lower,
        ccs.manager_underscored,
        ccs.hours_match_pattern,
        ccs.city_state
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_strings cstr ON cs.cs_bill_customer_sk = cstr.c_customer_sk
    JOIN item_strings istr ON cs.cs_item_sk = istr.i_item_sk
    JOIN call_center_strings ccs ON cs.cs_call_center_sk = ccs.cc_call_center_sk
)
SELECT
    d_year,
    city_state,
    cc_name_lower,
    manager_underscored,
    first_name_lower,
    last_name_upper,
    full_name_mixed,
    clean_email,
    login_prefix,
    substring(concat('ORD', cast(cs_order_number AS varchar)), 1, 8) AS order_id_prefix,
    length(cast(cs_order_number AS varchar)) AS order_id_len,
    sum(cs_quantity) AS total_quantity,
    sum(cs_net_paid) AS total_net_paid,
    sum(cs_net_profit) AS total_net_profit,
    avg(item_desc_len) AS avg_item_desc_len,
    avg(item_desc_word_cnt) AS avg_item_word_cnt,
    count(DISTINCT reversed_item_id) AS distinct_rev_item_ids,
    approx_distinct(full_name_mixed) AS approx_distinct_full_names,
    max(length(clean_email)) AS max_email_len,
    min(cs_net_paid) AS min_net_paid,
    sum(CASE WHEN hours_match_pattern THEN cs_net_paid ELSE 0 END) AS net_paid_hours_match,
    sum(CASE WHEN regexp_like(concat('ORD', cast(cs_order_number AS varchar)), '^ORD[0-9]+$') THEN 1 ELSE 0 END) AS cnt_valid_order_ids,
    reverse(city_state) AS rev_city_state,
    sum(length(regexp_replace(full_name_mixed, '[^AEIOUaeiou]', ''))) AS total_vowel_count_in_names,
    sum(length(regexp_replace(cast(cs_order_number AS varchar), '[^5]', ''))) AS total_fives_in_order_numbers
FROM sales_join
WHERE cs_net_paid > 0
GROUP BY
    d_year,
    city_state,
    cc_name_lower,
    manager_underscored,
    first_name_lower,
    last_name_upper,
    full_name_mixed,
    clean_email,
    login_prefix,
    cs_order_number,
    item_desc_len,
    item_desc_word_cnt,
    reversed_item_id,
    hours_match_pattern
HAVING sum(cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
