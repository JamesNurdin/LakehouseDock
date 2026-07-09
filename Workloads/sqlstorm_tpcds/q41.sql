SELECT
    s.s_store_id,
    s.s_store_name,
    concat_ws(', ', s.s_city, s.s_state) AS store_location,
    d.d_year,
    d.d_month_seq AS month,
    COUNT(*) AS sales_txn,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_quantity) AS avg_quantity,
    MAX(length(upper(s.s_store_name))) AS store_name_len,
    MIN(lower(concat_ws(' ', c.c_first_name, c.c_last_name))) AS min_customer_fullname_lc,
    MAX(substr(i.i_product_name, 1, 10)) AS max_product_name_prefix,
    COUNT(DISTINCT regexp_extract(i.i_item_id, '([0-9]+)', 1)) AS distinct_numeric_item_ids,
    MAX(replace(i.i_color, ' ', '_')) AS max_color_underscored,
    COUNT(DISTINCT concat_ws('|', lower(c.c_email_address), i.i_brand, s.s_city)) AS distinct_composite_keys,
    SUM(CASE WHEN i.i_color LIKE '%RED%' THEN 1 ELSE 0 END) AS red_items_count,
    AVG(length(regexp_replace(i.i_product_name, '\\s+', ''))) AS avg_product_name_no_spaces_len,
    approx_distinct(c.c_customer_sk) AS distinct_customers,
    MIN(split_part(c.c_login, '@', 1)) AS login_user
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE s.s_state = 'CA'
  AND d.d_year BETWEEN 1999 AND 2001
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 20
