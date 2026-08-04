WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
store_sales_enriched AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_wholesale_cost,
        ss.ss_list_price,
        ss.ss_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_list_price,
        ss.ss_ext_tax,
        ss.ss_coupon_amt,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        d.d_date,
        p.p_promo_name,
        ca.ca_city,
        cp.city_prefix,
        CASE WHEN regexp_like(ca.ca_state, '^[A-Z]{2}$') THEN ca.ca_state ELSE NULL END AS state_code
    FROM sampled_store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT regexp_extract(ca.ca_city, '^(.{3})', 1) AS city_prefix
    ) cp
),
web_sales_enriched AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_wholesale_cost,
        ws.ws_list_price,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        ws.ws_ext_wholesale_cost,
        ws.ws_ext_list_price,
        ws.ws_ext_tax,
        ws.ws_coupon_amt,
        ws.ws_ext_ship_cost,
        ws.ws_net_paid,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_paid_inc_ship,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_net_profit,
        d.d_date,
        p.p_promo_name AS wp_promo_name,
        wp.wp_url,
        wp.wp_autogen_flag,
        dom.domain,
        CASE WHEN wp.wp_url LIKE '%/sale%' THEN 1 ELSE 0 END AS is_sale_page
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN LATERAL (
        SELECT regexp_extract(wp.wp_url, '://([^/]+)/', 1) AS domain
    ) dom
    WHERE wp.wp_autogen_flag = 'N'
),
combined AS (
    SELECT
        COALESCE(ss.d_date, ws.d_date) AS sale_date,
        COALESCE(ss.p_promo_name, ws.wp_promo_name) AS promo_name,
        COALESCE(ss.city_prefix, ws.domain) AS key_str,
        ss.ss_net_paid AS store_net_paid,
        ws.ws_net_paid AS web_net_paid,
        ss.ss_net_profit AS store_profit,
        ws.ws_net_profit AS web_profit
    FROM store_sales_enriched ss
    FULL OUTER JOIN web_sales_enriched ws
        ON ss.d_date = ws.d_date
        AND ss.p_promo_name = ws.wp_promo_name
),
distinct_promos AS (
    SELECT DISTINCT promo_name FROM combined
),
final AS (
    SELECT
        c.sale_date,
        c.promo_name,
        c.key_str,
        SUM(COALESCE(c.store_net_paid, 0) + COALESCE(c.web_net_paid, 0)) OVER (
            PARTITION BY c.promo_name
            ORDER BY c.sale_date
            ROWS UNBOUNDED PRECEDING
        ) AS running_total_paid,
        LAG(c.store_profit) OVER (PARTITION BY c.promo_name ORDER BY c.sale_date) AS prev_store_profit,
        LEAD(c.web_profit) OVER (PARTITION BY c.promo_name ORDER BY c.sale_date) AS next_web_profit,
        CASE WHEN c.key_str LIKE '%A%' THEN 'ContainsA' ELSE 'NoA' END AS key_flag
    FROM combined c
    JOIN distinct_promos dp ON c.promo_name = dp.promo_name
    WHERE c.key_str IS NOT NULL
)
SELECT
    sale_date,
    promo_name,
    key_str,
    running_total_paid,
    prev_store_profit,
    next_web_profit,
    key_flag
FROM final
ORDER BY sale_date DESC, promo_name
LIMIT 100
