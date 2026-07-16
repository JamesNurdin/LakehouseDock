WITH base_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        i.i_product_name AS product_name,
        i.i_color AS color,
        i.i_size AS size,
        p.p_promo_name AS promo_name,
        p.p_channel_details AS channel_details,
        cc.cc_name AS call_center_name,
        cc.cc_manager AS call_center_manager,
        w.w_warehouse_name AS warehouse_name,
        d.d_date AS sale_date
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1999
)
SELECT
    sale_date,
    COUNT(*) AS num_orders,
    SUM(quantity) AS total_quantity,
    SUM(net_paid) AS total_net_paid,
    SUM(LENGTH(item_desc)) AS total_item_desc_len,
    SUM(LENGTH(REGEXP_REPLACE(item_desc, '\\s+', ''))) AS total_item_desc_nospace_len,
    SUM(CARDINALITY(regexp_extract_all(item_desc, '[aeiouAEIOU]'))) AS total_vowel_count_in_desc,
    AVG(LENGTH(item_desc)) AS avg_item_desc_len,
    MIN(LENGTH(item_desc)) AS min_item_desc_len,
    MAX(LENGTH(item_desc)) AS max_item_desc_len,
    SUM(LENGTH(item_id) - LENGTH(REGEXP_REPLACE(item_id, '\\d', ''))) AS total_digit_count_in_item_id,
    SUM(LENGTH(REVERSE(LOWER(promo_name)))) AS total_rev_lower_promo_name_len,
    COUNT(DISTINCT CASE WHEN REGEXP_LIKE(promo_name, '(?i)discount') THEN promo_name END) AS promo_names_with_discount,
    SUM(LENGTH(REGEXP_EXTRACT(channel_details, '(\\w+)', 1))) AS channel_details_first_word_len,
    COUNT(DISTINCT CASE WHEN REGEXP_LIKE(call_center_manager, '^.*Smith$') THEN call_center_manager END) AS call_center_managers_named_smith,
    COUNT(DISTINCT CASE WHEN REGEXP_LIKE(warehouse_name, '^.*Store$') THEN warehouse_name END) AS warehouses_ending_store,
    MAX(LENGTH(trim(call_center_name))) AS max_call_center_name_len,
    SUM(LENGTH(trim(promo_name, '%'))) AS total_promo_name_trim_len,
    COUNT(DISTINCT REGEXP_EXTRACT(item_desc, '(\\d{4})', 1)) AS distinct_4digit_codes_in_item_desc,
    SUM(LENGTH(split(product_name, ' ')[1])) AS total_first_word_len_product_name,
    SUM(CARDINALITY(split(product_name, ' '))) AS total_product_name_word_count,
    approx_percentile(LENGTH(product_name), 0.5) AS median_product_name_len,
    SUM(LENGTH(REGEXP_REPLACE(color, '[^a-zA-Z]', ''))) AS total_alpha_color_len,
    COUNT(DISTINCT CASE WHEN REGEXP_LIKE(size, '^\\d+([a-zA-Z]+)$') THEN size END) AS distinct_sizes_with_units,
    SUM(LENGTH(REPLACE(item_desc, '-', ''))) AS total_item_desc_without_hyphens,
    COUNT(DISTINCT CASE WHEN REGEXP_LIKE(item_desc, '\\b(NEW|USED)\\b') THEN item_desc END) AS distinct_new_or_used_desc,
    SUM(LENGTH(channel_details) - LENGTH(REGEXP_REPLACE(channel_details, '[aeiouAEIOU]', ''))) AS total_consonant_count_in_channel_details,
    COUNT(DISTINCT REGEXP_EXTRACT(item_desc, '([A-Z]{2,})', 1)) AS distinct_acronyms_in_item_desc,
    SUM(LENGTH(LOWER(item_desc))) AS total_lower_item_desc_len,
    SUM(LENGTH(UPPER(item_desc))) AS total_upper_item_desc_len,
    SUM(LENGTH(TRIM(item_desc))) AS total_trimmed_item_desc_len
FROM base_sales
GROUP BY sale_date
ORDER BY sale_date
