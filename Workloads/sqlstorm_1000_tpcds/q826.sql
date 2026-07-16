SELECT
    cc_call_center_id,
    cc_name,
    cc_state,
    cc_full_address,
    address_len,
    cc_name_no_vowels,
    cc_name_vowel_ct,
    email_lower,
    email_domain,
    email_domain_len,
    email_local_part,
    product_name_lower,
    brand_upper,
    product_name_len,
    product_name_underscored,
    product_name_vowel_count,
    cp_desc_no_newline,
    cp_desc_len,
    cp_desc_prefix,
    cp_desc_category_keyword,
    derived_date,
    address_rank_by_state,
    avg_product_name_len_by_state,
    total_net_profit_by_state
FROM (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        CONCAT_WS(' ', cc.cc_street_number, cc.cc_street_name, cc.cc_street_type, COALESCE(cc.cc_suite_number, ''), cc.cc_city, cc.cc_state, cc.cc_zip) AS cc_full_address,
        LENGTH(CONCAT_WS(' ', cc.cc_street_number, cc.cc_street_name, cc.cc_street_type, COALESCE(cc.cc_suite_number, ''), cc.cc_city, cc.cc_state, cc.cc_zip)) AS address_len,
        REGEXP_REPLACE(cc.cc_name, '[AEIOUaeiou]', '') AS cc_name_no_vowels,
        LENGTH(REGEXP_REPLACE(cc.cc_name, '[^AEIOUaeiou]', '')) AS cc_name_vowel_ct,
        LOWER(c.c_email_address) AS email_lower,
        SUBSTRING(c.c_email_address, strpos(c.c_email_address, '@') + 1) AS email_domain,
        LENGTH(SUBSTRING(c.c_email_address, strpos(c.c_email_address, '@') + 1)) AS email_domain_len,
        REGEXP_EXTRACT(c.c_email_address, '^([^@]+)@', 1) AS email_local_part,
        LOWER(i.i_product_name) AS product_name_lower,
        UPPER(i.i_brand) AS brand_upper,
        LENGTH(i.i_product_name) AS product_name_len,
        REGEXP_REPLACE(i.i_product_name, '\\s+', '_') AS product_name_underscored,
        regexp_count(i.i_product_name, '[aeiouAEIOU]') AS product_name_vowel_count,
        REPLACE(cp.cp_description, '\\n', ' ') AS cp_desc_no_newline,
        LENGTH(cp.cp_description) AS cp_desc_len,
        SUBSTRING(cp.cp_description, 1, 30) AS cp_desc_prefix,
        REGEXP_EXTRACT(cp.cp_description, '(?i)\\b(electronic|fashion|hardware)\\b', 1) AS cp_desc_category_keyword,
        date_add('day', d.d_date_sk, DATE '2021-01-01') AS derived_date,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY LENGTH(CONCAT_WS(' ', cc.cc_street_number, cc.cc_street_name, cc.cc_street_type))) AS address_rank_by_state,
        AVG(LENGTH(i.i_product_name)) OVER (PARTITION BY cc.cc_state) AS avg_product_name_len_by_state,
        SUM(cs.cs_net_profit) OVER (PARTITION BY cc.cc_state) AS total_net_profit_by_state
    FROM call_center cc
    JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cc.cc_state = ca.ca_state
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE cc.cc_rec_end_date > DATE '2024-10-01'
      AND c.c_preferred_cust_flag = 'Y'
      AND i.i_color IS NOT NULL
      AND cp.cp_description IS NOT NULL
) t
WHERE address_rank_by_state = 1
ORDER BY cc_state, address_len DESC
LIMIT 100
