WITH sales_enriched AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ca.ca_suite_number,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        sm.sm_carrier,
        p.p_promo_name,
        regexp_extract(ca.ca_street_name, '^([^ ]+)', 1) AS street_prefix,
        concat(ca.ca_city, ', ', ca.ca_state) AS city_state
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(ca.ca_suite_number, '^Suite [0-9]+$')
      AND regexp_like(p.p_promo_name, '(?i)discount')
      AND ca.ca_city LIKE '%York%'
)
SELECT
    sm_carrier,
    p_promo_name,
    street_prefix,
    city_state,
    SUM(ws_net_profit) AS total_profit,
    COUNT(*) AS order_count
FROM sales_enriched
GROUP BY
    sm_carrier,
    p_promo_name,
    street_prefix,
    city_state
ORDER BY total_profit DESC
LIMIT 100
