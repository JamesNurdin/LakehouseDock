WITH
customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
        lower(concat_ws(' ', c.c_first_name, c.c_last_name)) AS full_name_lc,
        replace(c.c_email_address, '@', '_at_') AS email_modified,
        length(c.c_email_address) AS email_len,
        regexp_replace(c.c_email_address, '\\W', '') AS email_alnum
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
),
item_data AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        lower(i.i_product_name) AS product_name_lc,
        replace(i.i_item_desc, '\n', ' ') AS desc_one_line,
        regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '') AS desc_alnum,
        length(i.i_item_desc) AS desc_len,
        substr(i.i_item_desc, 1, 50) AS desc_prefix
    FROM item i
),
page_data AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        lower(cp.cp_description) AS dept_desc_lc,
        regexp_replace(cp.cp_description, '\\s+', '_') AS desc_underscored,
        length(cp.cp_description) AS desc_len,
        cp.cp_description
    FROM catalog_page cp
),
call_center_data AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        lower(cc.cc_name) AS cc_name_lc,
        regexp_replace(cc.cc_name, '[^a-z]', '') AS cc_name_alpha,
        length(cc.cc_name) AS cc_name_len,
        substr(cc.cc_name, 1, 10) AS cc_name_prefix,
        replace(cc.cc_name, ' ', '_') AS cc_name_underscored
    FROM call_center cc
),
sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_wholesale_cost,
        cs.cs_list_price
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
)
SELECT
    c.full_name,
    c.email_modified,
    i.i_product_name,
    i.i_item_desc,
    p.cp_department,
    p.dept_desc_lc,
    cc.cc_name,
    cc.cc_name_prefix,
    lower(concat(c.full_name, ' - ', i.i_product_name)) AS lower_full_product,
    replace(p.dept_desc_lc, ' ', '-') AS dept_desc_dash,
    regexp_replace(i.i_item_desc, '[aeiou]', '*') AS desc_vowel_masked,
    regexp_replace(i.i_item_desc, '\\d+', '#') AS desc_digits_masked,
    substr(i.i_item_desc, strpos(i.i_item_desc, ' ') + 1, 30) AS after_first_space_30,
    concat_ws('||', c.email_modified, i.i_product_name) AS email_product_concat,
    array_join(ARRAY[c.full_name, i.i_product_name, p.cp_department], '|') AS combined_array_pipe,
    translate(cc.cc_name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') AS cc_name_lowercase,
    length(c.full_name) AS full_name_len,
    length(i.i_item_desc) AS item_desc_len,
    cc.cc_name_len,
    p.desc_len AS dept_desc_len,
    i.desc_len AS item_desc_len,
    count(*) OVER (PARTITION BY c.c_customer_id) AS cust_sales_count,
    sum(s.cs_quantity) OVER (PARTITION BY i.i_item_sk) AS total_quantity_by_item,
    sum(s.cs_net_paid) OVER (PARTITION BY p.cp_department) AS total_net_paid_by_department,
    row_number() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY s.cs_net_paid DESC) AS cc_sales_rank,
    dense_rank() OVER (ORDER BY length(c.full_name) DESC) AS full_name_len_rank
FROM sales_data s
JOIN customer_data c ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN item_data i ON s.cs_item_sk = i.i_item_sk
JOIN page_data p ON s.cs_catalog_page_sk = p.cp_catalog_page_sk
JOIN call_center_data cc ON s.cs_call_center_sk = cc.cc_call_center_sk
WHERE
    lower(c.full_name) LIKE '%smith%'
    AND p.cp_department LIKE '%Electronics%'
    AND cc.cc_name_alpha <> ''
ORDER BY cc_sales_rank, total_net_paid_by_department DESC
LIMIT 100
