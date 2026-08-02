WITH
catalog_agg AS (
    SELECT
        'catalog' AS source,
        i.i_item_id,
        i.i_product_name,
        substring(i.i_product_name, 1, 10) AS short_name,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(
            CASE
                WHEN p.p_discount_active = 'Y' THEN cs.cs_net_profit - cs.cs_ext_discount_amt
                ELSE cs.cs_net_profit
            END
        ) AS total_adj_profit,
        regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word,
        CASE WHEN i.i_product_name LIKE '%USB%' THEN 'USB' ELSE 'Other' END AS product_category,
        CAST(NULL AS varchar) AS domain,
        CAST(NULL AS varchar) AS url_segment
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
        t.t_hour BETWEEN 9 AND 17
        AND regexp_like(i.i_product_name, '[A-Z]{3}')
        AND cust.c_birth_month IN (5, 7, 10)
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        substring(i.i_product_name, 1, 10),
        regexp_extract(i.i_product_name, '(\\w+)', 1),
        CASE WHEN i.i_product_name LIKE '%USB%' THEN 'USB' ELSE 'Other' END
),
web_agg AS (
    SELECT
        'web' AS source,
        i.i_item_id,
        i.i_product_name,
        substring(i.i_product_name, 1, 10) AS short_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(
            CASE
                WHEN ws.ws_coupon_amt > 0 THEN ws.ws_net_profit - ws.ws_coupon_amt
                ELSE ws.ws_net_profit
            END
        ) AS total_adj_profit,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        u.url_part AS url_segment,
        CAST(NULL AS varchar) AS first_word,
        CAST(NULL AS varchar) AS product_category
    FROM
        web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
        CROSS JOIN LATERAL (
            SELECT split(wp.wp_url, '/') AS parts
        ) d
        CROSS JOIN UNNEST(d.parts) AS u (url_part)
    WHERE
        wp.wp_url LIKE 'http://%example.com%'
        AND t.t_hour BETWEEN 9 AND 18
        AND regexp_like(i.i_product_name, '.*\\d.*')
        AND cust.c_birth_day BETWEEN 1 AND 15
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        substring(i.i_product_name, 1, 10),
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1),
        u.url_part
),
union_all AS (
    SELECT
        source,
        i_item_id,
        i_product_name,
        short_name,
        order_count,
        total_adj_profit,
        domain,
        url_segment,
        first_word,
        product_category
    FROM
        catalog_agg
    UNION DISTINCT
    SELECT
        source,
        i_item_id,
        i_product_name,
        short_name,
        order_count,
        total_adj_profit,
        domain,
        url_segment,
        first_word,
        product_category
    FROM
        web_agg
)
SELECT
    source,
    i_item_id,
    i_product_name,
    short_name,
    order_count,
    total_adj_profit,
    COALESCE(domain, 'N/A') AS domain,
    url_segment,
    first_word,
    product_category,
    concat(i_product_name, '-', COALESCE(domain, 'N/A')) AS product_domain_concat
FROM
    union_all
ORDER BY
    total_adj_profit DESC,
    order_count DESC
LIMIT 100
