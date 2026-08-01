WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        sm.sm_carrier,
        p.p_promo_name,
        ca.ca_city,
        d.d_year,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d+)$') AS promo_code,
        CONCAT(sm.sm_carrier, ' - ', ca.ca_city) AS carrier_city
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)DISCOUNT')
      AND ca.ca_city LIKE 'A%'
      AND d.d_year = 2001
)
SELECT
    carrier_city,
    p_promo_name,
    promo_code,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(ws_quantity) AS avg_quantity,
    (SELECT MAX(p2.p_cost)
     FROM promotion p2
     WHERE p2.p_promo_name = filtered_sales.p_promo_name) AS max_promo_cost
FROM filtered_sales
GROUP BY carrier_city, p_promo_name, promo_code
HAVING SUM(ws_net_profit) > (
    SELECT AVG(ws3.ws_net_profit)
    FROM web_sales ws3
)
ORDER BY total_net_profit DESC
LIMIT 100
