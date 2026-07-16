WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS call_center_sk,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS web_page_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_catalog_page_sk AS catalog_page_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_quantity AS quantity,
        cs.cs_order_number AS order_number,
        'catalog' AS source
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        CAST(NULL AS integer),
        ss.ss_store_sk,
        CAST(NULL AS integer),
        ss.ss_promo_sk,
        CAST(NULL AS integer),
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_ticket_number,
        'store'
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        CAST(NULL AS integer),
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_order_number,
        'web'
    FROM web_sales ws
),
sales_extended AS (
    SELECT
        sd.*,
        d.d_year,
        d.d_month_seq,
        i.i_product_name,
        i.i_item_desc,
        i.i_color,
        i.i_size,
        cc.cc_name,
        st.s_store_name,
        wp.wp_url,
        pr.p_promo_name AS promo_name,
        cp.cp_description,
        cp.cp_type,
        concat(
            COALESCE(upper(substr(i.i_product_name,1,5)), ''),
            COALESCE(lower(substr(i.i_color,1,3)), ''),
            COALESCE(replace(i.i_size, ' ', ''), ''),
            COALESCE(substr(cc.cc_name,1,4), ''),
            COALESCE(substr(st.s_store_name,1,4), ''),
            COALESCE(regexp_replace(lower(wp.wp_url), '^https?://', ''), ''),
            COALESCE(substr(pr.p_promo_name,1,5), ''),
            COALESCE(substr(cp.cp_description,1,5), '')
        ) AS row_signature,
        array_join(
            transform(
                split(regexp_replace(lower(i.i_item_desc), '\\W+', ' '), ' '),
                t -> concat(substr(t,1,1), ':', CAST(length(t) AS varchar))
            ),
            '_'
        ) AS desc_token_pattern,
        cardinality(
            array_distinct(
                split(regexp_replace(lower(i.i_item_desc), '\\W+', ' '), ' ')
            )
        ) AS distinct_desc_token_count,
        CASE WHEN sd.source = 'web' THEN replace(regexp_replace(lower(wp.wp_url), '^https?://', ''), '/', '_') ELSE NULL END AS normalized_url,
        CASE WHEN sd.source = 'catalog' THEN lower(cp.cp_type) ELSE NULL END AS cp_type_lc
    FROM sales_data sd
    LEFT JOIN date_dim d ON sd.date_sk = d.d_date_sk
    LEFT JOIN item i ON sd.item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON sd.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store st ON sd.store_sk = st.s_store_sk
    LEFT JOIN web_page wp ON sd.web_page_sk = wp.wp_web_page_sk
    LEFT JOIN promotion pr ON sd.promo_sk = pr.p_promo_sk
    LEFT JOIN catalog_page cp ON sd.catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT
    se.d_year,
    se.d_month_seq,
    SUM(se.net_paid) AS total_net_paid,
    COUNT(DISTINCT se.order_number) AS total_orders,
    SUM(se.quantity) AS total_quantity,
    array_join(array_sort(array_agg(DISTINCT se.row_signature)), '|') AS signatures,
    array_join(array_sort(array_agg(DISTINCT se.cp_type_lc)), '|') AS catalog_page_types,
    array_join(array_sort(array_agg(DISTINCT se.normalized_url)), '|') AS normalized_urls,
    MAX(se.distinct_desc_token_count) AS max_distinct_desc_tokens,
    AVG(se.distinct_desc_token_count) AS avg_distinct_desc_tokens,
    array_join(array_sort(array_agg(DISTINCT se.desc_token_pattern)), '#') AS desc_token_patterns,
    array_join(array_sort(array_agg(DISTINCT upper(substr(se.promo_name,1,3)))), ',') AS promo_codes
FROM sales_extended se
GROUP BY se.d_year, se.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
