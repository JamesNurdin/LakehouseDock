WITH filtered_sales AS (
    SELECT
        i.i_category,
        ca.ca_state,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_code,
        concat(i.i_brand, '-', i.i_product_name) AS brand_product,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '\\d{3}[a-z]{3}')
      AND ca.ca_city LIKE 'San%'
)
SELECT
    i_category AS category,
    ca_state AS state,
    p_promo_name AS promo_name,
    promo_code,
    brand_product,
    SUM(ws_net_profit) AS total_profit,
    COUNT(*) AS order_count,
    AVG(ws_quantity) AS avg_quantity
FROM filtered_sales
GROUP BY
    i_category,
    ca_state,
    p_promo_name,
    promo_code,
    brand_product
HAVING SUM(ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
