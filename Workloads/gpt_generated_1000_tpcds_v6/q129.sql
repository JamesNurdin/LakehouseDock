WITH air_barry AS (
    SELECT
        sm.sm_carrier AS carrier,
        'AIR_Barry' AS segment,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_paid
    FROM tpcds.web_sales ws
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE sm.sm_code = 'AIR'
      AND ca.ca_county = 'Barry County'
    GROUP BY sm.sm_carrier
),
sea_kit AS (
    SELECT
        sm.sm_carrier AS carrier,
        'SEA_KitCarson' AS segment,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_paid
    FROM tpcds.web_sales ws
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE sm.sm_code = 'SEA'
      AND ca.ca_county = 'Kit Carson County'
    GROUP BY sm.sm_carrier
)
SELECT carrier, segment, total_paid
FROM air_barry
UNION ALL
SELECT carrier, segment, total_paid
FROM sea_kit
ORDER BY total_paid DESC
LIMIT 100
