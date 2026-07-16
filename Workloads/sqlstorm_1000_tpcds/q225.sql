WITH processed AS (
 SELECT
    c.c_customer_sk,
    c.c_customer_id,
    lower(trim(c.c_email_address)) AS email_lc,
    regexp_extract(c.c_email_address, '^([^@]+)@', 1) AS email_local,
    regexp_extract(c.c_email_address, '@([^\\.]+)\\.', 1) AS email_domain,
    c.c_login,
    concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS full_name,
    length(concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name)) AS full_name_len,
    i.i_item_sk,
    i.i_product_name,
    upper(i.i_product_name) AS product_name_upper,
    regexp_replace(i.i_product_name, '\\s+', '') AS product_name_no_spaces,
    length(i.i_product_name) AS product_name_len,
    lower(i.i_color) AS color_lc,
    case when lower(i.i_color) like 'red%' then 'red' else 'other' end AS color_category,
    regexp_extract(i.i_product_name, '([AEIOUaeiou]{2,})', 1) AS double_vowel_seq,
    concat_ws('-', i.i_brand, i.i_class, i.i_category) AS brand_class_category,
    cp.cp_description,
    regexp_replace(cp.cp_description, '[^A-Za-z0-9 ]', '') AS cp_desc_clean,
    cc.cc_name,
    reverse(cc.cc_name) AS cc_name_rev,
    upper(cc.cc_manager) AS cc_manager_up,
    w.w_warehouse_name,
    regexp_replace(w.w_warehouse_name, '\\s+', '_') AS warehouse_name_clean,
    concat_ws(', ', w.w_city, w.w_state) AS warehouse_location,
    p.p_promo_name,
    upper(p.p_promo_name) AS promo_name_up,
    t.t_meal_time,
    t.t_shift,
    d.d_day_name,
    d.d_date,
    cs.cs_quantity,
    case when cs.cs_quantity > 5 then 'bulk' else 'regular' end AS quantity_type,
    cs.cs_ext_sales_price,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    cs.cs_coupon_amt,
    ca.ca_street_number,
    ca.ca_street_name,
    ca.ca_street_type,
    ca.ca_suite_number,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip) AS address_line,
    regexp_replace(concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip), '[^A-Za-z0-9 ]', '') AS address_clean
 FROM
    catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
 WHERE
    c.c_preferred_cust_flag = 'Y'
    AND regexp_like(i.i_product_name, '\\b[AEIOUaeiou]{2,}\\b')
)
SELECT
    email_domain,
    color_category,
    quantity_type,
    count(DISTINCT c_customer_sk) AS num_customers,
    sum(cs_ext_sales_price) AS total_sales,
    avg(cs_net_profit) AS avg_profit,
    max(full_name_len) AS max_name_len,
    min(product_name_len) AS min_product_len,
    approx_percentile(cs_net_paid, 0.5) AS median_net_paid,
    array_agg(DISTINCT product_name_upper) AS product_names,
    array_agg(DISTINCT promo_name_up) AS promo_names,
    array_join(array_agg(DISTINCT warehouse_name_clean), ', ') AS warehouses,
    concat_ws(' | ', max(cp_desc_clean), max(cc_manager_up)) AS description_summary,
    array_join(array_agg(DISTINCT lower(cc_name_rev)), ', ') AS rev_cc_names,
    array_join(array_agg(DISTINCT email_lc), ', ') AS sample_emails,
    max(address_clean) AS sample_address
FROM processed
GROUP BY email_domain, color_category, quantity_type
HAVING count(*) >= 10
ORDER BY total_sales DESC
LIMIT 50
