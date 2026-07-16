WITH unified_sales AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        i.i_category AS i_category,
        i.i_product_name AS i_product_name,
        i.i_item_desc AS i_item_desc,
        c.c_first_name AS c_first_name,
        c.c_last_name AS c_last_name,
        c.c_email_address AS c_email_address,
        cs.cs_ext_sales_price AS sales_price,
        cc.cc_name AS channel_name,
        CAST(NULL AS varchar) AS url,
        cs.cs_order_number AS order_number,
        c.c_customer_id AS cust_id,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_product_name,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ws.ws_ext_sales_price,
        CAST(NULL AS varchar) AS channel_name,
        wp.wp_url AS url,
        ws.ws_order_number,
        c.c_customer_id,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_product_name,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ss.ss_ext_sales_price,
        s.s_store_name AS channel_name,
        CAST(NULL AS varchar) AS url,
        ss.ss_ticket_number,
        c.c_customer_id,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
)

SELECT
    d_year,
    d_month_seq,
    i_category,
    channel,
    COUNT(*) AS order_cnt,
    SUM(sales_price) AS total_sales,
    COUNT(DISTINCT cust_id) AS distinct_customers,
    AVG(length(i_product_name)) AS avg_product_name_len,
    AVG(cardinality(split(i_item_desc, ' '))) AS avg_desc_word_count,
    SUM(CASE WHEN lower(i_item_desc) LIKE '%premium%' THEN 1 ELSE 0 END) AS premium_desc_cnt,
    SUM(CASE WHEN lower(i_item_desc) LIKE '%eco%' THEN 1 ELSE 0 END) AS eco_desc_cnt,
    SUM(CASE WHEN lower(i_item_desc) LIKE '%new%' THEN 1 ELSE 0 END) AS new_desc_cnt,
    approx_distinct(regexp_extract(i_product_name, '\\d+', 0)) AS distinct_numbers_in_name,
    MAX(CAST(regexp_extract(i_product_name, '\\d+', 0) AS integer)) AS max_number_extracted,
    AVG(length(replace(i_product_name, '-', ''))) AS avg_name_len_no_dash,
    COUNT(DISTINCT substr(lower(i_product_name), 1, 3)) AS distinct_name_prefixes,
    SUM(CASE WHEN url IS NOT NULL THEN length(regexp_replace(url, '^https?://', '')) ELSE 0 END) AS total_url_len_without_scheme,
    SUM(CASE WHEN url IS NOT NULL THEN cardinality(split(coalesce(regexp_extract(url, '^https?://([^/]+)/', 1), ''), '\\.')) ELSE 0 END) AS total_url_domain_parts,
    AVG(length(concat_ws(' ', c_first_name, c_last_name))) AS avg_customer_full_name_len,
    MAX(length(c_email_address)) AS max_email_len,
    MIN(length(c_email_address)) AS min_email_len,
    SUM(CASE WHEN strpos(c_email_address, '@') > 0 THEN length(substr(c_email_address, 1, strpos(c_email_address, '@') - 1)) ELSE 0 END) AS total_email_user_part_len,
    COUNT(DISTINCT substr(lower(channel_name), 1, 5)) AS distinct_channel_name_prefixes,
    AVG(length(coalesce(channel_name, ''))) AS avg_channel_name_len
FROM unified_sales
GROUP BY d_year, d_month_seq, i_category, channel
HAVING COUNT(*) > 500
ORDER BY total_sales DESC
LIMIT 200
