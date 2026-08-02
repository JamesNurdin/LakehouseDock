WITH
    sub1 AS (
        SELECT ws.ws_order_number
        FROM web_sales ws
        INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        INNER JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE REGEXP_LIKE(p.p_channel_email, '^Y$')
          AND ca.ca_city LIKE '%York%'
          AND SUBSTRING(p.p_promo_name, 1, 5) = 'Promo'
    ),
    sub2 AS (
        SELECT ws.ws_order_number
        FROM web_sales ws
        INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        INNER JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender LIKE 'F%'
          AND REGEXP_LIKE(p.p_promo_name, '\\d')
          AND REGEXP_EXTRACT(p.p_promo_name, '\\d+') IS NOT NULL
    ),
    intersected_orders AS (
        SELECT ws_order_number FROM sub1
        INTERSECT
        SELECT ws_order_number FROM sub2
    )
SELECT
    ca.ca_state,
    COUNT(DISTINCT i.ws_order_number) AS order_count,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM intersected_orders i
INNER JOIN web_sales ws ON ws.ws_order_number = i.ws_order_number
INNER JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
GROUP BY ca.ca_state
ORDER BY total_net_profit DESC
LIMIT 100
