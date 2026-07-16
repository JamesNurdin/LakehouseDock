WITH customer_normalized AS (
    SELECT
        c.c_customer_sk,
        CONCAT_WS('_',
            LOWER(TRIM(c.c_first_name)),
            LOWER(TRIM(c.c_last_name)),
            REGEXP_REPLACE(REGEXP_EXTRACT(LOWER(c.c_email_address), '^([^@]+)@', 1), '\\W', '')
        ) AS cust_norm_id
    FROM customer c
    WHERE LOWER(c.c_preferred_cust_flag) = 'y'
),
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        SUM(ss.ss_net_paid) AS total_store_sales,
        AVG(ss.ss_net_profit) AS avg_store_profit,
        REPLACE(UPPER(s.s_store_name), ' ', '') AS store_name_clean,
        REGEXP_REPLACE(s.s_city, '\\s+', '_') AS store_city_fingerprint
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY ss.ss_customer_sk, s.s_store_name, s.s_city
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS ws_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        SUM(ws.ws_net_paid) AS total_web_sales,
        AVG(ws.ws_net_profit) AS avg_web_profit,
        LOWER(REGEXP_REPLACE(wp.wp_url, '[^a-z0-9]', '_')) AS url_fingerprint,
        REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)', 1) AS url_domain,
        CONCAT_WS('_', LOWER(wp.wp_type), UPPER(SUBSTRING(wp.wp_url, 1, 5))) AS wp_type_url_key
    FROM web_sales ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY ws.ws_bill_customer_sk, wp.wp_url, wp.wp_type
),
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cs_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        AVG(cs.cs_net_profit) AS avg_catalog_profit,
        SUBSTRING(COALESCE(p.p_promo_name, ''), 1, 10) AS promo_prefix,
        CASE
            WHEN REGEXP_LIKE(COALESCE(p.p_promo_name, ''), '.*SUMMER.*') THEN 'SummerPromo'
            WHEN REGEXP_LIKE(COALESCE(p.p_promo_name, ''), '.*WINTER.*') THEN 'WinterPromo'
            ELSE 'OtherPromo'
        END AS promo_type,
        REGEXP_REPLACE(COALESCE(cp.cp_department, ''), '\\s+', '_') AS catalog_department_fingerprint
    FROM catalog_sales cs
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cs.cs_bill_customer_sk, p.p_promo_name, cp.cp_department
),
item_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        ARRAY_JOIN(ARRAY_AGG(DISTINCT i.i_product_name), '|') AS product_names_concat,
        MAX(LENGTH(i.i_product_name)) AS max_product_name_len,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items,
        CARDINALITY(SPLIT(ARRAY_JOIN(ARRAY_AGG(DISTINCT i.i_item_desc), ' '), '\\s+')) AS total_desc_word_cnt,
        ELEMENT_AT(SPLIT(MAX_BY(i.i_item_desc, LENGTH(i.i_item_desc)), '\\s+'), 1) AS longest_item_desc_first_word,
        UPPER(REGEXP_REPLACE(MAX(i.i_product_name), '[^A-Za-z0-9]', '')) AS product_clean_max
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ss.ss_customer_sk
)
SELECT
    cn.cust_norm_id,
    cn.c_customer_sk,
    ss.store_orders,
    ss.total_store_sales,
    ss.avg_store_profit,
    ss.store_name_clean,
    ss.store_city_fingerprint,
    ws.web_orders,
    ws.total_web_sales,
    ws.avg_web_profit,
    ws.url_fingerprint,
    ws.url_domain,
    ws.wp_type_url_key,
    cs.catalog_orders,
    cs.total_catalog_sales,
    cs.avg_catalog_profit,
    cs.promo_prefix,
    cs.promo_type,
    cs.catalog_department_fingerprint,
    i.product_names_concat,
    i.max_product_name_len,
    i.distinct_items,
    i.total_desc_word_cnt,
    i.longest_item_desc_first_word,
    i.product_clean_max
FROM customer_normalized cn
LEFT JOIN store_sales_agg ss ON cn.c_customer_sk = ss.ss_customer_sk
LEFT JOIN web_sales_agg ws ON cn.c_customer_sk = ws.ws_customer_sk
LEFT JOIN catalog_sales_agg cs ON cn.c_customer_sk = cs.cs_customer_sk
LEFT JOIN item_agg i ON cn.c_customer_sk = i.cust_sk
WHERE cn.cust_norm_id IS NOT NULL
ORDER BY ss.total_store_sales DESC NULLS LAST
LIMIT 200
