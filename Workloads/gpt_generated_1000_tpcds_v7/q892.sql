WITH avg_price AS (
    SELECT avg(i_current_price) AS avg_price
    FROM item
)
SELECT
    sm.sm_carrier,
    sm.sm_code,
    CONCAT(sm.sm_carrier, '-', sm.sm_code) AS carrier_code,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_tax) AS total_tax,
    MIN(ws.ws_sold_time_sk) AS first_time_sk,
    MAX(ws.ws_sold_time_sk) AS last_time_sk
FROM
    web_sales ws
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
CROSS JOIN avg_price ap
WHERE
    i.i_current_price > ap.avg_price
    AND regexp_like(i.i_item_desc, '(?i)deluxe')
    AND wp.wp_url LIKE '%.com%'
    AND substring(sm.sm_carrier, 1, 1) = 'P'
    AND EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = ws.ws_ship_mode_sk
          AND sm2.sm_contract LIKE '%-%'
    )
GROUP BY
    sm.sm_carrier,
    sm.sm_code,
    CONCAT(sm.sm_carrier, '-', sm.sm_code)
ORDER BY
    total_net_paid DESC
LIMIT 10
