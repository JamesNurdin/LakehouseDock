SELECT
    d.d_year,
    lower(trim(cc.cc_name)) AS cc_name_clean,
    substr(cp.cp_type, 1, 3) AS cp_type_prefix,
    regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '') AS i_item_desc_alpha,
    length(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')) AS i_item_desc_len,
    concat_ws(' ', c.c_first_name, c.c_last_name) AS cust_full_name,
    upper(cp.cp_department) AS cp_department_upper,
    replace(cc.cc_hours, ':', '-') AS cc_hours_dash,
    regexp_extract(cp.cp_description, '\\d+', 0) AS first_digit_in_desc,
    cardinality(split(i.i_item_desc, ' ')) AS i_item_desc_word_cnt,
    upper(i.i_product_name) AS product_name_upper,
    length(i.i_product_name) AS product_name_len,
    array_join(array_agg(DISTINCT lower(p.p_promo_name)), '|') AS promos_concat,
    sum(cs.cs_ext_sales_price) AS total_sales,
    sum(cs.cs_net_profit) AS total_profit,
    count(DISTINCT cs.cs_order_number) AS distinct_orders,
    min(d.d_date) AS min_date,
    max(d.d_date) AS max_date
FROM
    catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE
    d.d_year >= 1999
    AND p.p_discount_active = 'Y'
GROUP BY
    d.d_year,
    lower(trim(cc.cc_name)),
    substr(cp.cp_type, 1, 3),
    regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', ''),
    length(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')),
    concat_ws(' ', c.c_first_name, c.c_last_name),
    upper(cp.cp_department),
    replace(cc.cc_hours, ':', '-'),
    regexp_extract(cp.cp_description, '\\d+', 0),
    cardinality(split(i.i_item_desc, ' ')),
    upper(i.i_product_name),
    length(i.i_product_name)
