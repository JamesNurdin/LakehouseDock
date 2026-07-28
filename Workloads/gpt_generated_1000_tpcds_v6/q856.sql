SELECT ship_mode_id,
       ship_mode_code,
       total_net_profit,
       source
FROM (
      SELECT sm.sm_ship_mode_id AS ship_mode_id,
             sm.sm_code        AS ship_mode_code,
             SUM(cs.cs_net_profit) AS total_net_profit,
             'catalog'         AS source
      FROM catalog_sales cs
      JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN customer c   ON cs.cs_bill_customer_sk = c.c_customer_sk
      WHERE sm.sm_code IN ('AIR', 'SEA')
        AND c.c_first_sales_date_sk >= 2450000
      GROUP BY sm.sm_ship_mode_id, sm.sm_code

      UNION ALL

      SELECT sm.sm_ship_mode_id AS ship_mode_id,
             sm.sm_code        AS ship_mode_code,
             SUM(ws.ws_net_profit) AS total_net_profit,
             'web'               AS source
      FROM web_sales ws
      JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN customer c   ON ws.ws_bill_customer_sk = c.c_customer_sk
      WHERE sm.sm_code IN ('AIR', 'SEA')
        AND c.c_first_sales_date_sk >= 2450000
      GROUP BY sm.sm_ship_mode_id, sm.sm_code
) AS combined
ORDER BY total_net_profit DESC, source
LIMIT 100
