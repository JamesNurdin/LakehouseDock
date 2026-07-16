WITH cte_item AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_color,
           i.i_size,
           i.i_brand,
           i.i_class,
           i.i_category,
           lower(i.i_product_name) AS product_name_lc,
           length(i.i_product_name) AS product_name_len,
           length(regexp_replace(i.i_product_name, '[^AEIOUaeiou]', '')) AS vowel_count,
           array_join(
               transform(split(i.i_product_name, '\\s+'), x -> substr(x,1,1)),
               ''
           ) AS product_abbrev,
           regexp_replace(i.i_product_name, '[^[:alnum:][:space:]]', '') AS clean_product_name
    FROM item i
),
cte_page AS (
    SELECT cp.cp_catalog_page_sk,
           cp.cp_description,
           regexp_replace(cp.cp_description, '[^[:alnum:][:space:]]', '') AS clean_description,
           lower(cp.cp_type) AS type_lc,
           length(cp.cp_description) AS desc_len,
           array_join(
               transform(split(lower(cp.cp_type), '\\s+'), x -> substr(x,1,1)),
               ''
           ) AS type_abbrev
    FROM catalog_page cp
),
cte_call_center AS (
    SELECT cc.cc_call_center_sk,
           cc.cc_name,
           lower(cc.cc_name) AS name_lc,
           regexp_replace(cc.cc_name, '[[:space:]]+', '_') AS name_underscore,
           length(cc.cc_name) AS name_len,
           reverse(cc.cc_name) AS name_rev
    FROM call_center cc
),
cte_customer AS (
    SELECT c.c_customer_sk,
           concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS full_name,
           lower(trim(c.c_email_address)) AS email_norm,
           regexp_extract(lower(c.c_email_address), '@(.+)', 1) AS email_domain,
           reverse(regexp_extract(lower(c.c_email_address), '@(.+)', 1)) AS domain_rev,
           ca.ca_address_sk,
           concat_ws(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type,
                     ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
),
cte_sales AS (
    SELECT cs.cs_sold_date_sk,
           d.d_date,
           d.d_year,
           format_datetime(d.d_date, 'yyyy-MM-dd') AS sold_date_str,
           cs.cs_bill_customer_sk AS cs_customer_sk,
           cs.cs_item_sk,
           cs.cs_catalog_page_sk,
           cs.cs_call_center_sk,
           cs.cs_order_number,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_net_profit,
           i.product_name_lc,
           i.product_name_len,
           i.vowel_count,
           i.product_abbrev,
           i.clean_product_name,
           cp.clean_description,
           cp.type_lc,
           cp.desc_len,
           cp.type_abbrev,
           cc.name_lc,
           cc.name_rev,
           cc.name_underscore,
           concat_ws(' - ', cc.name_lc, cp.type_lc, i.product_abbrev) AS sales_key
    FROM catalog_sales cs
    JOIN cte_item i ON cs.cs_item_sk = i.i_item_sk
    JOIN cte_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN cte_call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
)
SELECT
    c.full_name,
    c.email_norm,
    c.email_domain,
    c.domain_rev,
    c.full_address,
    s.sold_date_str,
    s.cs_order_number,
    s.cs_quantity,
    s.cs_net_paid,
    s.name_rev,
    s.type_abbrev,
    s.product_abbrev,
    s.vowel_count,
    s.product_name_len,
    s.desc_len,
    concat_ws(' | ',
              c.full_name,
              s.name_rev,
              s.type_abbrev,
              s.product_abbrev,
              s.clean_description,
              s.clean_product_name) AS benchmark_string,
    sum(s.cs_net_paid) OVER (PARTITION BY c.c_customer_sk) AS total_paid_per_customer,
    approx_percentile(s.cs_quantity, 0.5) OVER (PARTITION BY c.c_customer_sk) AS median_quantity_per_customer,
    row_number() OVER (PARTITION BY c.c_customer_sk ORDER BY s.cs_sold_date_sk DESC) AS recent_sale_rank
FROM cte_customer c
JOIN cte_sales s ON c.c_customer_sk = s.cs_customer_sk
WHERE s.d_year = 2001
ORDER BY total_paid_per_customer DESC
LIMIT 100
