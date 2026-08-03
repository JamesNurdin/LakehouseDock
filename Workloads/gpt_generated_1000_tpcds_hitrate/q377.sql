WITH sales_data AS (
   SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        i.i_product_name,
        p.p_promo_name,
        sm.sm_ship_mode_id,
        sm.sm_code,
        ca.ca_state,
        ca.ca_city
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE sm.sm_code = 'AIR'
     AND regexp_like(p.p_promo_name, '(?i)discount|sale')
     AND i.i_product_name LIKE '%-%'
) 
SELECT
    sd.sm_ship_mode_id AS ship_mode_id,
    CONCAT('Promo_', SUBSTRING(sd.p_promo_name, 1, 8)) AS short_promo,
    COUNT(DISTINCT sd.ca_state) AS distinct_states,
    SUM(DISTINCT sd.ws_ext_sales_price) AS sum_distinct_sales,
    AVG(CASE WHEN sd.ws_quantity > 5 THEN sd.ws_net_paid ELSE NULL END) AS avg_net_paid_high_qty,
    MAX(CASE WHEN regexp_like(sd.i_product_name, '\\d{3}') THEN sd.ws_ext_sales_price ELSE 0 END) AS max_price_with_3digit_prod,
    COUNT(DISTINCT regexp_extract(sd.i_product_name, '(\\d{3})', 1)) AS distinct_product_codes
FROM sales_data sd
GROUP BY
    sd.sm_ship_mode_id,
    CONCAT('Promo_', SUBSTRING(sd.p_promo_name, 1, 8))
ORDER BY sum_distinct_sales DESC
LIMIT 100
