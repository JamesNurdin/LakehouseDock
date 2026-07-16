WITH
customer_profile AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        lower(c.c_email_address) AS email,
        split_part(c.c_email_address, '@', 2) AS email_domain,
        trim(concat_ws(' ', c.c_first_name, c.c_last_name)) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        concat_ws(', ', ca.ca_city, ca.ca_state, ca.ca_zip) AS location,
        concat_ws(' - ', trim(concat_ws(' ', c.c_first_name, c.c_last_name)), c.c_email_address, ca.ca_city, ca.ca_state) AS profile_string,
        length(concat_ws(' ', c.c_first_name, c.c_last_name, c.c_email_address, ca.ca_city, ca.ca_state, ca.ca_zip)) AS raw_profile_len,
        length(regexp_replace(concat_ws(' ', c.c_first_name, c.c_last_name, c.c_email_address, ca.ca_city, ca.ca_state, ca.ca_zip), '[^A-Za-z0-9]', '')) AS cleaned_profile_len,
        length(regexp_replace(lower(concat_ws(' ', c.c_first_name, c.c_last_name, c.c_email_address, ca.ca_city, ca.ca_state, ca.ca_zip)), '[^aeiou]', '')) AS vowel_count,
        length(regexp_replace(lower(concat_ws(' ', c.c_first_name, c.c_last_name, c.c_email_address, ca.ca_city, ca.ca_state, ca.ca_zip)), '[^bcdfghjklmnpqrstvwxyz]', '')) AS consonant_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_clean AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_item_desc,
        i.i_product_name,
        trim(regexp_replace(i.i_item_desc, '\\s+', ' ')) AS cleaned_desc,
        length(trim(regexp_replace(i.i_item_desc, '\\s+', ' '))) AS cleaned_desc_len,
        cardinality(split(trim(regexp_replace(i.i_item_desc, '\\s+', ' ')), ' ')) AS word_count,
        lower(trim(regexp_replace(i.i_item_desc, '\\s+', ' '))) AS lower_desc,
        length(regexp_replace(lower(trim(regexp_replace(i.i_item_desc, '\\s+', ' '))), '[^aeiou]', '')) AS vowel_count,
        length(regexp_replace(lower(trim(regexp_replace(i.i_item_desc, '\\s+', ' '))), '[^bcdfghjklmnpqrstvwxyz]', '')) AS consonant_count,
        concat_ws(' - ', i.i_product_name, i.i_item_desc) AS full_product_string
    FROM item i
),
store_metrics AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        COUNT(DISTINCT ss.ss_customer_sk) AS num_customers,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ic.cleaned_desc_len) AS avg_item_desc_len,
        MAX(ic.word_count) AS max_item_word_count,
        AVG(cp.vowel_count) AS avg_customer_vowel_count,
        MAX(cp.consonant_count) AS max_customer_consonant_count,
        array_join(array_agg(DISTINCT lower(cp.email_domain)), ',') AS distinct_email_domains,
        array_join(array_agg(DISTINCT ic.i_category), ',') AS distinct_product_categories,
        concat_ws(' | ', s.s_store_name, s.s_city, s.s_state) AS store_full_string,
        length(regexp_replace(lower(concat_ws(' ', s.s_store_name, s.s_city, s.s_state)), '[^a-z]', '')) AS store_string_alpha_len
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN customer_profile cp ON ss.ss_customer_sk = cp.c_customer_sk
    JOIN item_clean ic ON ss.ss_item_sk = ic.i_item_sk
    WHERE s.s_state IN ('CA', 'TX', 'NY', 'FL')
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state
    HAVING SUM(ss.ss_quantity) > 100
)
SELECT
    sm.s_store_id,
    sm.s_store_name,
    sm.s_city,
    sm.s_state,
    sm.num_customers,
    sm.total_net_paid,
    sm.avg_item_desc_len,
    sm.max_item_word_count,
    sm.avg_customer_vowel_count,
    sm.max_customer_consonant_count,
    sm.distinct_email_domains,
    sm.distinct_product_categories,
    sm.store_full_string,
    sm.store_string_alpha_len,
    ROW_NUMBER() OVER (ORDER BY sm.total_net_paid DESC) AS sales_rank
FROM store_metrics sm
ORDER BY sm.total_net_paid DESC
LIMIT 20
