WITH item_desc_processed AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        lower(regexp_replace(i.i_item_desc, '[^a-z0-9]', '')) AS norm_item_desc,
        length(i.i_item_desc) AS item_desc_len,
        length(lower(regexp_replace(i.i_item_desc, '[^a-z0-9]', ''))) AS norm_item_desc_len,
        concat(i.i_category, ' > ', i.i_class, ' > ', i.i_brand) AS category_path,
        substr(i.i_item_id, 1, 3) AS item_id_prefix,
        upper(substr(i.i_item_id, 4)) AS item_id_suffix,
        concat(substr(i.i_item_id, 1, 3), '-', substr(i.i_item_id, 4)) AS sku_code
    FROM item i
),
customer_email_processed AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        lower(c.c_email_address) AS email_lc,
        regexp_extract(lower(c.c_email_address), '@([^.]*)', 1) AS email_domain,
        length(regexp_extract(lower(c.c_email_address), '@([^.]*)', 1)) AS domain_len,
        trim(c.c_first_name) || ' ' || trim(c.c_last_name) AS full_name,
        length(trim(c.c_first_name) || ' ' || trim(c.c_last_name)) AS full_name_len
    FROM customer c
),
store_address_processed AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        concat(
            s.s_street_number, ' ', s.s_street_name,
            coalesce(concat(' ', s.s_street_type), ''),
            ', ', s.s_city, ', ', s.s_state, ' ', s.s_zip
        ) AS raw_address,
        trim(regexp_replace(
            concat(
                s.s_street_number, ' ', s.s_street_name,
                coalesce(concat(' ', s.s_street_type), ''),
                ', ', s.s_city, ', ', s.s_state, ' ', s.s_zip
            ), '\\s+', ' '
        )) AS normalized_address,
        length(trim(regexp_replace(
            concat(
                s.s_street_number, ' ', s.s_street_name,
                coalesce(concat(' ', s.s_street_type), ''),
                ', ', s.s_city, ', ', s.s_state, ' ', s.s_zip
            ), '\\s+', ' '
        ))) AS address_len
    FROM store s
),
promo_text_processed AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_details,
        lower(regexp_replace(p.p_promo_name, '\\s+', ' ')) AS norm_promo_name,
        length(p.p_promo_name) AS promo_name_len,
        length(lower(regexp_replace(p.p_promo_name, '\\s+', ' '))) AS norm_promo_name_len,
        regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS discount_percent
    FROM promotion p
),
sales_aggregated AS (
    SELECT
        ip.category_path,
        ip.sku_code,
        ip.norm_item_desc,
        ip.norm_item_desc_len,
        ip.item_desc_len,
        ce.email_domain,
        ce.domain_len,
        sa.normalized_address,
        sa.address_len,
        pt.norm_promo_name,
        pt.norm_promo_name_len,
        sum(ws.ws_net_paid) AS total_web_net_paid,
        sum(ss.ss_net_paid) AS total_store_net_paid,
        sum(cs.cs_net_paid) AS total_catalog_net_paid,
        count(distinct ws.ws_order_number) AS web_orders,
        count(distinct ss.ss_ticket_number) AS store_orders,
        count(distinct cs.cs_order_number) AS catalog_orders,
        sum(ws.ws_quantity) AS qty_web,
        sum(ss.ss_quantity) AS qty_store,
        sum(cs.cs_quantity) AS qty_catalog,
        sum(CASE WHEN regexp_like(ip.norm_item_desc, '.*[0-9]{3}.*') THEN 1 ELSE 0 END) AS desc_with_triple_digit
    FROM item_desc_processed ip
    LEFT JOIN store_sales ss ON ss.ss_item_sk = ip.i_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN customer_email_processed ce ON ss.ss_customer_sk = ce.c_customer_sk
    LEFT JOIN store_address_processed sa ON s.s_store_sk = sa.s_store_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = ip.i_item_sk
    LEFT JOIN promo_text_processed pt ON ws.ws_promo_sk = pt.p_promo_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = ip.i_item_sk
    WHERE ip.norm_item_desc IS NOT NULL
    GROUP BY
        ip.category_path,
        ip.sku_code,
        ip.norm_item_desc,
        ip.norm_item_desc_len,
        ip.item_desc_len,
        ce.email_domain,
        ce.domain_len,
        sa.normalized_address,
        sa.address_len,
        pt.norm_promo_name,
        pt.norm_promo_name_len
)
SELECT
    category_path,
    sku_code,
    count(*) AS category_product_cnt,
    sum(total_web_net_paid) + sum(total_store_net_paid) + sum(total_catalog_net_paid) AS total_net_paid,
    sum(qty_web) + sum(qty_store) + sum(qty_catalog) AS total_quantity,
    avg(norm_item_desc_len) AS avg_norm_desc_len,
    approx_distinct(email_domain) AS distinct_email_domains,
    max(domain_len) AS max_email_domain_len,
    min(address_len) AS min_store_address_len,
    max(address_len) AS max_store_address_len,
    approx_percentile(total_web_net_paid, 0.5) AS median_web_net_paid,
    regexp_replace(concat_ws(' - ', norm_promo_name, norm_item_desc), '\\s+', ' ') AS combined_text,
    length(regexp_replace(concat_ws(' - ', norm_promo_name, norm_item_desc), '\\s+', ' ')) AS combined_text_len
FROM sales_aggregated
GROUP BY
    category_path,
    sku_code,
    norm_promo_name,
    norm_item_desc
ORDER BY total_net_paid DESC
LIMIT 50
