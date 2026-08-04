WITH a AS (
    SELECT DISTINCT ws.ws_bill_addr_sk AS address_sk,
           CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2021
      AND sm.sm_type = 'AIR'
),

b AS (
    SELECT DISTINCT ws.ws_bill_addr_sk AS address_sk,
           CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2020
      AND sm.sm_type = 'SEA'
),

c AS (
    SELECT DISTINCT ws.ws_bill_addr_sk AS address_sk,
           CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2022
      AND sm.sm_type = 'SURFACE'
),

intersect_ab AS (
    SELECT address_sk, profit_flag FROM a
    INTERSECT
    SELECT address_sk, profit_flag FROM b
)
SELECT address_sk, profit_flag
FROM intersect_ab
EXCEPT
SELECT address_sk, profit_flag FROM c
ORDER BY address_sk
LIMIT 100
