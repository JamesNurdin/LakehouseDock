WITH
call_center_str AS (
  SELECT
    cc.cc_call_center_sk,
    upper(trim(cc.cc_name)) AS cc_name_up,
    reverse(upper(trim(cc.cc_name))) AS cc_name_rev,
    regexp_replace(lower(cc.cc_manager), '[^a-z]', '') AS cc_manager_alpha
  FROM call_center cc
),
catalog_page_str AS (
  SELECT
    cp.cp_catalog_page_sk,
    regexp_replace(lower(cp.cp_description), '\\W+', ' ') AS cp_desc_clean,
    replace(regexp_replace(lower(cp.cp_description), '\\W+', ' '), ' ', '_') AS cp_desc_underscored,
    length(regexp_replace(lower(cp.cp_description), '\\W+', ' ')) AS cp_desc_len,
    repeat(cp.cp_type, 3) AS cp_type_repeat
  FROM catalog_page cp
),
item_str AS (
  SELECT
    i.i_item_sk,
    substring(i.i_product_name, 1, 10) AS i_name_prefix,
    length(i.i_color) AS i_color_len,
    concat_ws('_', i.i_brand, i.i_class, i.i_category) AS item_hierarchy,
    length(concat_ws('_', i.i_brand, i.i_class, i.i_category)) AS item_hierarchy_len,
    lower(i.i_brand) AS i_brand_lower
  FROM item i
),
date_str AS (
  SELECT
    d.d_date_sk,
    d.d_year,
    upper(d.d_day_name) AS day_name_up,
    reverse(upper(d.d_day_name)) AS day_name_rev
  FROM date_dim d
),
web_page_summary AS (
  SELECT
    max(length(wp.wp_url)) AS max_url_len,
    any_value(regexp_replace(wp.wp_url, '^https?://', '')) AS sample_url_no_proto,
    regexp_extract(any_value(regexp_replace(wp.wp_url, '^https?://', '')), '^([^/]+)', 1) AS url_domain
  FROM web_page wp
),
catalog_sales_agg AS (
  SELECT
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    cs.cs_item_sk,
    cs.cs_sold_date_sk,
    sum(cs.cs_quantity) AS total_quantity,
    sum(cs.cs_net_paid) AS total_net_paid
  FROM catalog_sales cs
  GROUP BY cs.cs_call_center_sk, cs.cs_catalog_page_sk, cs.cs_item_sk, cs.cs_sold_date_sk
)
SELECT
  cc.cc_call_center_sk,
  cc.cc_name_up,
  cc.cc_name_rev,
  cc.cc_manager_alpha,
  cp.cp_desc_clean,
  cp.cp_desc_underscored,
  cp.cp_desc_len,
  cp.cp_type_repeat,
  i.i_name_prefix,
  i.i_color_len,
  i.item_hierarchy,
  i.item_hierarchy_len,
  i.i_brand_lower,
  d.d_year,
  d.day_name_up,
  d.day_name_rev,
  csag.total_quantity,
  csag.total_net_paid,
  wp.max_url_len,
  wp.sample_url_no_proto,
  wp.url_domain,
  concat_ws('|', cc.cc_name_up, cp.cp_desc_clean, i.item_hierarchy) AS composite_key
FROM call_center_str cc
JOIN catalog_sales_agg csag ON csag.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page_str cp ON cp.cp_catalog_page_sk = csag.cs_catalog_page_sk
JOIN item_str i ON i.i_item_sk = csag.cs_item_sk
JOIN date_str d ON d.d_date_sk = csag.cs_sold_date_sk
CROSS JOIN web_page_summary wp
WHERE
  cc.cc_name_up LIKE '%DIVISION%'
  AND cp.cp_desc_clean LIKE '%new%'
  AND i.item_hierarchy LIKE '%M%'
ORDER BY csag.total_net_paid DESC
LIMIT 100
