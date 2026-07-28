WITH store_data AS (
    SELECT
        ca.ca_state AS state,
        SUM(sr.sr_net_loss) AS amount,
        'store' AS channel
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY ca.ca_state
),
web_data AS (
    SELECT
        ca.ca_state AS state,
        SUM(ws.ws_net_profit) AS amount,
        'web' AS channel
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'UPS'
      AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY ca.ca_state
)
SELECT *
FROM store_data
UNION ALL
SELECT *
FROM web_data
LIMIT 100
