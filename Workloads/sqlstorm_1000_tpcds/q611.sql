WITH catalog_data AS (
    SELECT
        'catalog' AS source,
        d.d_year,
        d.d_month_seq,
        cc.cc_name AS location_name,
        i.i_product_name,
        i.i_item_desc,
        cp.cp_description,
        cp.cp_type,
        cc.cc_hours,
        ca.ca_city,
        ca.ca_zip,
        ca.ca_state,
        ca.ca_country,
        LENGTH(i.i_product_name) AS prod_name_len,
        LENGTH(REGEXP_REPLACE(i.i_product_name, '\\s+', '')) AS prod_name_nospace_len,
        CARDINALITY(SPLIT(i.i_product_name, '\\s+')) AS prod_name_word_cnt,
        LOWER(i.i_product_name) AS prod_name_lower,
        LENGTH(cp.cp_description) AS cat_desc_len,
        CARDINALITY(SPLIT(cp.cp_description, '\\s+')) AS cat_desc_word_cnt,
        LENGTH(REGEXP_REPLACE(cc.cc_hours, '[^0-9]', '')) AS hours_digit_len,
        LENGTH(REGEXP_REPLACE(ca.ca_zip, '[^0-9]', '')) AS zip_digit_len,
        NULL AS url_len,
        NULL AS url_segment_cnt,
        NULL AS url_domain,
        NULL AS domain_len
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
),
web_data AS (
    SELECT
        'web' AS source,
        d.d_year,
        d.d_month_seq,
        wsit.web_name AS location_name,
        i.i_product_name,
        i.i_item_desc,
        NULL AS cp_description,
        NULL AS cp_type,
        NULL AS cc_hours,
        ca.ca_city,
        ca.ca_zip,
        ca.ca_state,
        ca.ca_country,
        LENGTH(i.i_product_name) AS prod_name_len,
        LENGTH(REGEXP_REPLACE(i.i_product_name, '\\s+', '')) AS prod_name_nospace_len,
        CARDINALITY(SPLIT(i.i_product_name, '\\s+')) AS prod_name_word_cnt,
        LOWER(i.i_product_name) AS prod_name_lower,
        NULL AS cat_desc_len,
        NULL AS cat_desc_word_cnt,
        NULL AS hours_digit_len,
        LENGTH(REGEXP_REPLACE(ca.ca_zip, '[^0-9]', '')) AS zip_digit_len,
        LENGTH(wp.wp_url) AS url_len,
        CARDINALITY(SPLIT(wp.wp_url, '/')) AS url_segment_cnt,
        REGEXP_EXTRACT(wp.wp_url, '^https?://([^/]+)/', 1) AS url_domain,
        LENGTH(REGEXP_EXTRACT(wp.wp_url, '^https?://([^/]+)/', 1)) AS domain_len
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
)
SELECT
    source,
    d_year,
    d_month_seq,
    location_name,
    AVG(prod_name_len) AS avg_product_name_len,
    AVG(prod_name_nospace_len) AS avg_product_name_nospace_len,
    AVG(prod_name_word_cnt) AS avg_product_name_word_cnt,
    COUNT(DISTINCT prod_name_lower) AS distinct_product_name_lower_cnt,
    AVG(COALESCE(cat_desc_len, 0)) AS avg_catalog_desc_len,
    AVG(COALESCE(cat_desc_word_cnt, 0)) AS avg_catalog_desc_word_cnt,
    AVG(COALESCE(hours_digit_len, 0)) AS avg_hours_digit_len,
    AVG(COALESCE(zip_digit_len, 0)) AS avg_zip_digit_len,
    AVG(COALESCE(url_len, 0)) AS avg_url_len,
    AVG(COALESCE(url_segment_cnt, 0)) AS avg_url_segment_cnt,
    COUNT(DISTINCT url_domain) AS distinct_url_domains_cnt,
    AVG(COALESCE(domain_len, 0)) AS avg_url_domain_len
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
) u
GROUP BY source, d_year, d_month_seq, location_name
ORDER BY source, d_year, d_month_seq, location_name
