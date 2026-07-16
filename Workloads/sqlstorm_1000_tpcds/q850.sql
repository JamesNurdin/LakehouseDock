WITH
call_center_clean AS (
    SELECT
        cc_call_center_sk,
        cc_call_center_id,
        lower(regexp_replace(cc_name, '[^A-Za-z0-9]', '')) AS clean_name,
        length(cc_name) AS name_len,
        trim(cc_hours) AS trimmed_hours,
        concat_ws(' ', cc_street_number, cc_street_name, cc_street_type, coalesce(cc_suite_number, '')) AS address,
        lower(cc_state) AS state_lc,
        lower(cc_city) AS city_lc,
        lower(cc_country) AS country_lc,
        concat(substr(lower(regexp_replace(cc_name, '[^A-Za-z0-9]', '')), 1, 3), '-', substr(lower(cc_state), 1, 2)) AS cc_key
    FROM call_center
),
customer_clean AS (
    SELECT
        c_customer_sk,
        lower(regexp_replace(concat(c_first_name, ' ', c_last_name), '\\s+', ' ')) AS clean_full_name,
        lower(substr(c_email_address, 1, 5)) AS email_prefix,
        lower(substr(c_login, 1, 3)) AS login_prefix,
        length(c_email_address) AS email_len,
        length(c_login) AS login_len
    FROM customer
),
item_clean AS (
    SELECT
        i_item_sk,
        lower(regexp_replace(i_item_desc, '[^A-Za-z0-9 ]', '')) AS clean_desc,
        length(i_item_desc) AS desc_len,
        regexp_extract(i_item_desc, '([0-9]+)', 1) AS first_number_in_desc,
        cardinality(split(i_item_desc, ' ')) AS word_count
    FROM item
),
promo_clean AS (
    SELECT
        p_promo_sk,
        lower(p_promo_name) AS promo_name_lc,
        regexp_replace(p_promo_name, '\\s+', '') AS promo_name_nospace,
        length(p_promo_name) AS promo_name_len,
        substr(p_promo_name, 1, 4) AS promo_name_prefix
    FROM promotion
),
sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        sum(cs.cs_net_paid) AS total_cs_net,
        sum(cs.cs_ext_sales_price) AS total_cs_sales,
        count(*) AS cs_order_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk
)
SELECT
    cc.cc_call_center_id,
    cc.clean_name,
    cc.name_len,
    cc.trimmed_hours,
    cc.address,
    upper(concat(cc.city_lc, ', ', cc.state_lc)) AS location_upper,
    cc.cc_key,
    coalesce(sa.total_cs_net, 0) AS total_sales_net,
    coalesce(sa.cs_order_cnt, 0) AS total_orders,
    max(cust.clean_full_name) AS sample_customer_name,
    max(cust.email_prefix) AS sample_email_prefix,
    avg(ic.desc_len) AS avg_item_desc_len,
    sum(CASE WHEN regexp_like(ic.clean_desc, 'sale') THEN 1 ELSE 0 END) AS items_with_sale,
    count(DISTINCT pc.promo_name_nospace) AS distinct_promo_variants,
    max(pc.promo_name_prefix) AS max_promo_prefix,
    count(DISTINCT s.s_store_sk) AS matching_stores,
    count(DISTINCT w.w_warehouse_id) AS matching_warehouses
FROM call_center_clean cc
LEFT JOIN sales_agg sa ON sa.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN customer_clean cust
    ON lower(substr(cust.clean_full_name, 1, 1)) = lower(substr(cc.clean_name, 1, 1))
LEFT JOIN item_clean ic
    ON regexp_like(ic.clean_desc, concat('.*', lower(substr(cc.clean_name, 1, 4)), '.*'))
LEFT JOIN promo_clean pc
    ON lower(substr(pc.promo_name_nospace, 1, 2)) = lower(substr(cc.clean_name, 1, 2))
LEFT JOIN store s
    ON lower(s.s_state) = cc.state_lc AND lower(s.s_city) = cc.city_lc
LEFT JOIN warehouse w
    ON lower(w.w_state) = cc.state_lc
GROUP BY
    cc.cc_call_center_id,
    cc.clean_name,
    cc.name_len,
    cc.trimmed_hours,
    cc.address,
    cc.city_lc,
    cc.state_lc,
    cc.cc_key,
    sa.total_cs_net,
    sa.cs_order_cnt
