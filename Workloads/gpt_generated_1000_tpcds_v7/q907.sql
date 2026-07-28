WITH catalog_data AS (
    SELECT cs.cs_order_number AS order_number,
           cs.cs_net_paid AS net_amount,
           sm.sm_ship_mode_id AS ship_mode,
           'catalog' AS source
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
      AND sm.sm_contract = 'HVDFCcQ'
),
web_data AS (
    SELECT ws.ws_order_number AS order_number,
           ws.ws_net_paid AS net_amount,
           sm.sm_ship_mode_id AS ship_mode,
           'web' AS source
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
      AND sm.sm_contract = 'HVDFCcQ'
)
SELECT order_number,
       net_amount,
       ship_mode,
       source
FROM catalog_data
UNION ALL
SELECT order_number,
       net_amount,
       ship_mode,
       source
FROM web_data
ORDER BY net_amount DESC
