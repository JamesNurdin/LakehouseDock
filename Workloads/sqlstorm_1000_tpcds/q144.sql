SELECT
    i.i_item_id,
    i.i_product_name,
    concat_ws(' ', i.i_brand, i.i_color, i.i_size) AS item_brand_color_size,
    lower(i.i_item_desc) AS item_desc_lower,
    regexp_extract(i.i_item_desc, '(?i)(\\w+)', 1) AS first_word_desc,
    length(i.i_item_desc) AS item_desc_len,
    regexp_like(i.i_item_desc, '\\b(premium|deluxe)\\b') AS is_premium_item,
    COALESCE(cs_sub.catalog_orders, 0) AS catalog_orders,
    COALESCE(cs_sub.catalog_quantity, 0) AS catalog_quantity,
    COALESCE(cs_sub.catalog_net_paid, 0) AS catalog_net_paid,
    COALESCE(cs_sub.catalog_email_domains, '') AS catalog_email_domains,
    COALESCE(cs_sub.catalog_customers, '') AS catalog_customers,
    COALESCE(cs_sub.catalog_page_descs, '') AS catalog_page_descs,
    COALESCE(cc_sub.call_center_managers, '') AS call_center_managers,
    COALESCE(cc_sub.call_center_names, '') AS call_center_names,
    COALESCE(ss_sub.store_transactions, 0) AS store_transactions,
    COALESCE(ss_sub.store_quantity, 0) AS store_quantity,
    COALESCE(ss_sub.store_net_paid, 0) AS store_net_paid,
    COALESCE(ss_sub.store_email_domains, '') AS store_email_domains,
    COALESCE(ss_sub.store_customers, '') AS store_customers,
    COALESCE(ss_sub.store_names, '') AS store_names,
    COALESCE(ss_sub.store_locations, '') AS store_locations,
    COALESCE(ws_sub.web_orders, 0) AS web_orders,
    COALESCE(ws_sub.web_quantity, 0) AS web_quantity,
    COALESCE(ws_sub.web_net_paid, 0) AS web_net_paid,
    COALESCE(ws_sub.web_email_domains, '') AS web_email_domains,
    COALESCE(ws_sub.web_customers, '') AS web_customers,
    COALESCE(ws_sub.web_promo_names, '') AS web_promo_names,
    COALESCE(ws_sub.web_page_urls, '') AS web_page_urls,
    COALESCE(ws_sub.web_url_domains, '') AS web_url_domains,
    COALESCE(ws_sub.web_url_domains_lower, '') AS web_url_domains_lower
FROM
    item i
LEFT JOIN (
    SELECT
        cs.cs_item_sk,
        count(DISTINCT cs.cs_order_number) AS catalog_orders,
        sum(cs.cs_quantity) AS catalog_quantity,
        sum(cs.cs_net_paid) AS catalog_net_paid,
        array_join(array_distinct(array_agg(regexp_extract(c.c_email_address, '@([^@]+)$', 1))), ', ') AS catalog_email_domains,
        array_join(array_distinct(array_agg(c.c_first_name || ' ' || c.c_last_name)), ', ') AS catalog_customers,
        array_join(array_distinct(array_agg(lower(cp.cp_description))), ', ') AS catalog_page_descs
    FROM
        catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY
        cs.cs_item_sk
) cs_sub ON cs_sub.cs_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT
        cs.cs_item_sk,
        array_join(array_distinct(array_agg(cc.cc_manager)), ', ') AS call_center_managers,
        array_join(array_distinct(array_agg(lower(cc.cc_name))), ', ') AS call_center_names
    FROM
        catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY
        cs.cs_item_sk
) cc_sub ON cc_sub.cs_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT
        ss.ss_item_sk,
        count(DISTINCT ss.ss_ticket_number) AS store_transactions,
        sum(ss.ss_quantity) AS store_quantity,
        sum(ss.ss_net_paid) AS store_net_paid,
        array_join(array_distinct(array_agg(regexp_extract(c.c_email_address, '@([^@]+)$', 1))), ', ') AS store_email_domains,
        array_join(array_distinct(array_agg(c.c_first_name || ' ' || c.c_last_name)), ', ') AS store_customers,
        array_join(array_distinct(array_agg(s.s_store_name)), ', ') AS store_names,
        array_join(array_distinct(array_agg(s.s_city || ', ' || s.s_state)), ', ') AS store_locations
    FROM
        store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        ss.ss_item_sk
) ss_sub ON ss_sub.ss_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT
        ws.ws_item_sk,
        count(DISTINCT ws.ws_order_number) AS web_orders,
        sum(ws.ws_quantity) AS web_quantity,
        sum(ws.ws_net_paid) AS web_net_paid,
        array_join(array_distinct(array_agg(regexp_extract(c.c_email_address, '@([^@]+)$', 1))), ', ') AS web_email_domains,
        array_join(array_distinct(array_agg(c.c_first_name || ' ' || c.c_last_name)), ', ') AS web_customers,
        array_join(array_distinct(array_agg(p.p_promo_name)), ', ') AS web_promo_names,
        array_join(array_distinct(array_agg(wp.wp_url)), ', ') AS web_page_urls,
        array_join(array_distinct(array_agg(regexp_extract(wp.wp_url, 'https?://([^/]+)', 1))), ', ') AS web_url_domains,
        array_join(array_distinct(array_agg(lower(regexp_extract(wp.wp_url, 'https?://([^/]+)', 1)))), ', ') AS web_url_domains_lower
    FROM
        web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY
        ws.ws_item_sk
) ws_sub ON ws_sub.ws_item_sk = i.i_item_sk
WHERE
    regexp_like(i.i_item_desc, '(?i)premium')
    AND (COALESCE(cs_sub.catalog_quantity, 0) + COALESCE(ss_sub.store_quantity, 0) + COALESCE(ws_sub.web_quantity, 0)) > 100
ORDER BY
    catalog_net_paid DESC
LIMIT 100
