WITH item_strings AS (
    SELECT
        i.i_item_sk,
        lower(i.i_product_name) AS prod_name_lower,
        regexp_replace(i.i_product_name, '\\s+', '_') AS prod_name_underscores,
        substr(i.i_product_name, 1, 10) AS prod_name_prefix,
        reverse(i.i_product_name) AS prod_name_rev,
        length(i.i_item_desc) AS desc_len,
        length(regexp_replace(lower(i.i_item_desc), '[^aeiou]', '')) AS vowel_count,
        cardinality(split(i.i_item_desc, ' ')) - 1 AS space_count,
        concat_ws('|', lower(i.i_brand), lower(i.i_category), lower(i.i_color)) AS normalized_brand_cat_color,
        regexp_replace(i.i_item_desc, '[^A-Za-z0-9]', '') AS alphanumeric_desc
    FROM item i
),
customer_strings AS (
    SELECT
        c.c_customer_sk,
        element_at(split(c.c_email_address, '@'), 2) AS email_domain,
        substr(element_at(split(c.c_email_address, '@'), 2), 1, 3) AS email_dom_prefix,
        lower(c.c_first_name) || '_' || lower(c.c_last_name) AS customer_user,
        length(c.c_login) AS login_len
    FROM customer c
),
call_center_strings AS (
    SELECT
        cc.cc_call_center_sk,
        replace(cc.cc_name, ' ', '-') AS cc_name_hyphen,
        lower(cc.cc_manager) AS cc_manager_lower,
        substr(cc.cc_manager, 1, 5) AS cc_manager_prefix
    FROM call_center cc
),
catalog_page_strings AS (
    SELECT
        cp.cp_catalog_page_sk,
        length(cp.cp_description) AS cp_desc_len,
        regexp_replace(cp.cp_description, '\\s+', ' ') AS cp_desc_normalized,
        lower(cp.cp_type) AS cp_type_lower
    FROM catalog_page cp
),
promotion_strings AS (
    SELECT
        p.p_promo_sk,
        lower(p.p_promo_name) AS promo_name_lower,
        regexp_replace(p.p_promo_name, '\\W+', '') AS promo_name_alnum
    FROM promotion p
),
sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_ext_sales_price) AS total_ext_sales,
        sum(cs.cs_net_profit) AS total_profit,
        count(*) AS sales_count
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_bill_customer_sk, cs.cs_call_center_sk, cs.cs_catalog_page_sk, cs.cs_promo_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    istrings.prod_name_lower,
    istrings.prod_name_underscores,
    istrings.prod_name_prefix,
    istrings.prod_name_rev,
    istrings.desc_len,
    istrings.vowel_count,
    istrings.space_count,
    istrings.normalized_brand_cat_color,
    istrings.alphanumeric_desc,
    c_strings.email_domain,
    c_strings.email_dom_prefix,
    c_strings.customer_user,
    c_strings.login_len,
    cc_strings.cc_name_hyphen,
    cc_strings.cc_manager_lower,
    cc_strings.cc_manager_prefix,
    cp_strings.cp_desc_len,
    cp_strings.cp_desc_normalized,
    cp_strings.cp_type_lower,
    p_strings.promo_name_lower,
    p_strings.promo_name_alnum,
    sagg.total_net_paid,
    sagg.total_ext_sales,
    sagg.total_profit,
    sagg.sales_count
FROM
    sales_agg sagg
    JOIN item i ON i.i_item_sk = sagg.cs_item_sk
    LEFT JOIN item_strings istrings ON istrings.i_item_sk = i.i_item_sk
    LEFT JOIN customer_strings c_strings ON c_strings.c_customer_sk = sagg.cs_bill_customer_sk
    LEFT JOIN call_center_strings cc_strings ON cc_strings.cc_call_center_sk = sagg.cs_call_center_sk
    LEFT JOIN catalog_page_strings cp_strings ON cp_strings.cp_catalog_page_sk = sagg.cs_catalog_page_sk
    LEFT JOIN promotion_strings p_strings ON p_strings.p_promo_sk = sagg.cs_promo_sk
