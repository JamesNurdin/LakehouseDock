WITH item_metrics AS (
    SELECT
        i_item_sk,
        i_product_name,
        lower(i_product_name) AS prod_name_lc,
        regexp_replace(i_product_name, '[^A-Za-z0-9 ]', '') AS prod_name_clean,
        length(i_product_name) AS prod_name_len,
        length(regexp_replace(lower(i_product_name), '[^aeiou]', '')) AS vowel_cnt,
        (length(regexp_replace(lower(i_product_name), '[^aeiou]', '')) * 1.0) / nullif(length(i_product_name), 0) AS vowel_ratio,
        cardinality(split(i_product_name, ' ')) AS token_cnt,
        element_at(split(i_product_name, ' '), 1) AS first_token,
        element_at(split(i_product_name, ' '), cardinality(split(i_product_name, ' '))) AS last_token
    FROM item
    WHERE i_product_name IS NOT NULL
),
store_metrics AS (
    SELECT
        s_store_sk,
        s_store_name,
        lower(s_store_name) AS store_name_lc,
        concat_ws(' ', s_street_number, s_street_name, s_street_type, s_suite_number, s_city, s_state, s_zip, s_country) AS full_address,
        length(concat_ws(' ', s_street_number, s_street_name, s_street_type, s_suite_number, s_city, s_state, s_zip, s_country)) AS address_len,
        regexp_like(s_store_name, '\\d') AS name_has_digit,
        lower(s_city) AS city_lc,
        substr(lower(s_city), 1, 3) AS city_prefix,
        upper(substr(s_state, 1, 2)) AS state_abbrev
    FROM store
    WHERE s_store_name IS NOT NULL
),
call_center_metrics AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        lower(cc_name) AS cc_name_lc,
        length(cc_name) AS cc_name_len,
        regexp_replace(cc_name, '[^A-Za-z0-9 ]', '') AS cc_name_clean,
        cardinality(split(cc_name, ' ')) AS cc_name_word_cnt,
        lower(cc_city) AS city_lc,
        substr(lower(cc_city), 1, 3) AS city_prefix,
        cc_manager,
        concat_ws(' ', split(cc_manager, ' ')[2], split(cc_manager, ' ')[3]) AS manager_last_two,
        regexp_like(cc_manager, '[A-Z]{2,}') AS manager_has_acronym
    FROM call_center
    WHERE cc_name IS NOT NULL
),
catalog_page_metrics AS (
    SELECT
        cp_catalog_page_sk,
        cp_description,
        lower(cp_description) AS desc_lc,
        length(cp_description) AS desc_len,
        cardinality(split(cp_description, ' ')) AS desc_word_cnt,
        regexp_like(cp_description, '\\d+') AS desc_has_number,
        regexp_replace(cp_description, '\\s+', ' ') AS desc_normalized
    FROM catalog_page
    WHERE cp_description IS NOT NULL
)
SELECT
    s.s_store_name,
    c.cc_name,
    i.i_product_name,
    cp.cp_description,
    s.state_abbrev AS store_state_abbrev,
    i.token_cnt,
    s.address_len,
    c.cc_name_len,
    cp.desc_word_cnt,
    i.vowel_ratio,
    s.name_has_digit,
    c.manager_has_acronym,
    cp.desc_has_number,
    concat_ws(' | ', s.s_store_name, c.cc_name, i.i_product_name, cp.cp_description) AS composite_string,
    length(concat_ws(' | ', s.s_store_name, c.cc_name, i.i_product_name, cp.cp_description)) AS composite_len,
    length(regexp_replace(lower(concat_ws('', s.s_store_name, c.cc_name, i.i_product_name, cp.cp_description)), '[^a-z]', '')) AS letters_only_len,
    cardinality(split(lower(concat_ws(' ', s.s_store_name, c.cc_name, i.i_product_name, cp.cp_description)), ' ')) AS total_token_cnt,
    CASE WHEN s.city_prefix = c.city_prefix THEN 1 ELSE 0 END AS city_prefix_match,
    CASE WHEN upper(i.first_token) = s.state_abbrev THEN 1 ELSE 0 END AS prod_first_token_state_match
FROM store_metrics s
JOIN call_center_metrics c
    ON s.city_lc = c.city_lc
JOIN item_metrics i
    ON upper(i.first_token) = s.state_abbrev
JOIN catalog_page_metrics cp
    ON cp.desc_has_number = false
WHERE s.address_len > 20
    AND i.vowel_ratio > 0.2
ORDER BY composite_len DESC
LIMIT 100
