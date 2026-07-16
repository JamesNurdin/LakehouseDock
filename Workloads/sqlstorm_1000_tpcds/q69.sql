WITH item_strings AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_color,
        i.i_size,
        concat_ws('_', i.i_brand, i.i_color, i.i_size) AS product_key,
        regexp_extract(i.i_product_name, '([A-Z]{2}[0-9]+)', 1) AS product_code_extracted,
        replace(i.i_product_name, ' ', '_') AS prod_name_underscored,
        substr(i.i_product_name, 1, 15) AS prod_name_prefix,
        cardinality(split(i.i_product_name, '\\s+')) AS prod_name_word_count,
        CASE
            WHEN i.i_color LIKE '%RED%' THEN 'Red'
            WHEN i.i_color LIKE '%BLUE%' THEN 'Blue'
            ELSE 'Other'
        END AS color_category
    FROM item i
),
store_strings AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_manager,
        s.s_hours,
        concat_ws(' - ', s.s_store_name, s.s_city, s.s_state) AS store_full_location,
        length(concat_ws(' - ', s.s_store_name, s.s_city, s.s_state)) AS full_loc_len,
        lower(s.s_manager) AS manager_lower,
        upper(s.s_manager) AS manager_upper,
        regexp_replace(s.s_hours, '\\s+', ' ') AS normalized_hours,
        cardinality(split(s.s_hours, '\\s+')) AS hours_parts_cnt,
        substr(s.s_manager, 1, 1) AS manager_initial
    FROM store s
)
SELECT
    st.s_store_id,
    st.store_full_location,
    st.manager_lower,
    st.manager_initial,
    st.full_loc_len,
    st.normalized_hours,
    st.hours_parts_cnt,
    d.d_year,
    count(*) AS total_transactions,
    sum(ss.ss_quantity) AS total_quantity,
    sum(ss.ss_net_paid) AS total_net_paid,
    sum(ss.ss_ext_sales_price) AS total_ext_sales,
    avg(it.prod_name_word_count) AS avg_prod_name_word_cnt,
    max(it.product_code_extracted) FILTER (WHERE it.product_code_extracted IS NOT NULL) AS any_product_code,
    array_join(array_agg(DISTINCT it.color_category), ', ') AS color_categories,
    array_join(array_agg(DISTINCT it.product_key), '|') AS concatenated_product_keys
FROM store_sales ss
JOIN store_strings st ON ss.ss_store_sk = st.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item_strings it ON ss.ss_item_sk = it.i_item_sk
WHERE it.prod_name_word_count > 2
  AND regexp_like(it.i_product_name, '[A-Z]{2}[0-9]{3}')
GROUP BY
    st.s_store_id,
    st.store_full_location,
    st.manager_lower,
    st.manager_initial,
    st.full_loc_len,
    st.normalized_hours,
    st.hours_parts_cnt,
    d.d_year
ORDER BY total_net_paid DESC
LIMIT 100
