WITH
prod_desc AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        lower(i.i_item_desc) AS desc_lower,
        regexp_replace(lower(i.i_item_desc), '[^a-z0-9 ]', '') AS desc_clean,
        length(regexp_replace(lower(i.i_item_desc), '[^a-z0-9 ]', '')) AS desc_len,
        strpos(lower(i.i_item_desc), 'red') AS pos_red,
        cardinality(split(i.i_item_desc, ' ')) AS word_count
    FROM item i
),
cust_info AS (
    SELECT
        c.c_customer_sk,
        concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
        lower(c.c_email_address) AS email_lower,
        split_part(lower(c.c_email_address), '@', 2) AS email_domain,
        regexp_replace(lower(c.c_email_address), '[^a-z0-9@.]', '') AS email_clean,
        length(c.c_login) AS login_len,
        substr(c.c_login, 1, 1) AS login_initial
    FROM customer c
),
store_info AS (
    SELECT
        s.s_store_sk,
        trim(both ' ' FROM s.s_store_name) AS store_name_trim,
        upper(s.s_city) || ', ' || upper(s.s_state) AS location_upper,
        lower(s.s_store_name) AS store_name_lower,
        length(s.s_store_name) AS store_name_len
    FROM store s
),
web_info AS (
    SELECT
        wp.wp_web_page_sk,
        lower(wp.wp_url) AS url_lower,
        regexp_replace(wp.wp_url, '^https?://', '') AS url_no_proto,
        replace(wp.wp_url, ' ', '') AS url_nospace,
        length(wp.wp_url) AS url_len,
        strpos(lower(wp.wp_url), 'catalog') AS pos_catalog
    FROM web_page wp
),
cc_info AS (
    SELECT
        cc.cc_call_center_sk,
        lower(cc.cc_name) AS cc_name_lower,
        regexp_replace(cc.cc_hours, '[^0-9:-]', '') AS cc_hours_clean,
        replace(cc.cc_manager, ' ', '_') AS cc_manager_underscore,
        length(cc.cc_name) AS cc_name_len
    FROM call_center cc
)
SELECT
    d.d_year,
    p.i_category,
    s.store_name_trim,
    s.location_upper,
    c.full_name,
    c.email_domain,
    c.email_clean,
    p.desc_clean,
    p.desc_len,
    p.pos_red,
    p.word_count,
    w.url_no_proto,
    w.url_len,
    w.pos_catalog,
    cc.cc_name_lower,
    cc.cc_hours_clean,
    cc.cc_manager_underscore,
    COUNT(*) AS trans_cnt,
    SUM(ss.ss_net_paid) AS total_sales,
    AVG(ss.ss_quantity) AS avg_qty,
    MIN(ss.ss_net_paid) AS min_sale,
    MAX(ss.ss_net_paid) AS max_sale,
    SUM(CASE WHEN p.desc_clean LIKE '%clearance%' THEN 1 ELSE 0 END) AS clearance_cnt,
    COUNT(DISTINCT c.email_domain) AS distinct_email_domains,
    array_join(array_agg(DISTINCT substr(c.full_name, 1, 1)), ',') AS initials_concat,
    MAX(length(c.email_clean)) AS max_email_clean_len,
    MAX(cc.cc_name_len) AS max_cc_name_len
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN prod_desc p ON ss.ss_item_sk = p.i_item_sk
JOIN cust_info c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store_info s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN web_info w ON mod(ss.ss_item_sk, 1000) = mod(w.wp_web_page_sk, 1000)
LEFT JOIN cc_info cc ON mod(ss.ss_store_sk, 1000) = mod(cc.cc_call_center_sk, 1000)
GROUP BY
    d.d_year,
    p.i_category,
    s.store_name_trim,
    s.location_upper,
    c.full_name,
    c.email_domain,
    c.email_clean,
    p.desc_clean,
    p.desc_len,
    p.pos_red,
    p.word_count,
    w.url_no_proto,
    w.url_len,
    w.pos_catalog,
    cc.cc_name_lower,
    cc.cc_hours_clean,
    cc.cc_manager_underscore
ORDER BY d.d_year DESC, total_sales DESC
LIMIT 100
