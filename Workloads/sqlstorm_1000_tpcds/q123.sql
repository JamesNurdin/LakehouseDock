WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        i.i_product_name,
        i.i_item_desc,
        i.i_color,
        i.i_brand,
        i.i_manufact,
        p.p_promo_name,
        p.p_channel_details,
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CAST(NULL AS varchar) AS wp_url,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        i.i_product_name,
        i.i_item_desc,
        i.i_color,
        i.i_brand,
        i.i_manufact,
        p.p_promo_name,
        p.p_channel_details,
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CAST(NULL AS varchar) AS wp_url,
        'store' AS source
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        i.i_product_name,
        i.i_item_desc,
        i.i_color,
        i.i_brand,
        i.i_manufact,
        p.p_promo_name,
        p.p_channel_details,
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        wp.wp_url,
        'web' AS source
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
transformed AS (
    SELECT
        d.d_year,
        us.source,
        us.i_product_name,
        us.i_item_desc,
        us.i_color,
        us.i_brand,
        us.i_manufact,
        us.ca_address_id,
        us.ca_city,
        us.ca_state,
        us.ca_zip,
        us.p_promo_name,
        us.p_channel_details,
        us.wp_url,
        us.net_paid,
        us.quantity,
        lower(us.i_product_name) AS product_name_lower,
        upper(us.i_product_name) AS product_name_upper,
        regexp_extract(us.i_product_name, '(\\d+)', 1) AS product_num,
        length(us.i_product_name) AS product_name_len,
        substring(us.i_product_name, 1, 3) AS product_prefix,
        replace(us.i_color, ' ', '_') AS color_underscore,
        CASE
            WHEN us.i_color LIKE '%Red%' THEN 'R'
            WHEN us.i_color LIKE '%Blue%' THEN 'B'
            ELSE 'O'
        END AS color_code,
        cardinality(split(us.i_item_desc, ' ')) AS desc_word_cnt,
        substring(us.i_item_desc, 1, 30) AS short_desc,
        translate(us.i_item_desc, 'AEIOUaeiou', '') AS desc_no_vowels,
        reverse(us.i_product_name) AS product_name_rev,
        concat_ws('_', us.source, us.i_brand, us.i_color) AS composite_key,
        regexp_replace(us.ca_address_id, '^([A-Z]{2})([0-9]+)', '\\1-\\2') AS formatted_address_id,
        concat_ws(', ', us.ca_city, us.ca_state, us.ca_zip) AS address_summary,
        replace(us.p_channel_details, ',', ' ') AS cleaned_channel_details
    FROM unified_sales us
    JOIN date_dim d ON us.date_sk = d.d_date_sk
)SELECT * FROM transformed
