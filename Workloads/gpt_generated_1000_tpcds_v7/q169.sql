WITH catalog_data AS (
   SELECT c.c_customer_id,
          c.c_first_name,
          c.c_last_name,
          cs.cs_net_profit        AS net_profit,
          'catalog'               AS channel
   FROM tpcds.catalog_sales cs
   JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE sm.sm_carrier = 'LATVIAN'
     AND cc.cc_city = 'Fairview'
     AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
),
web_data AS (
   SELECT c.c_customer_id,
          c.c_first_name,
          c.c_last_name,
          ws.ws_net_profit        AS net_profit,
          'web'                   AS channel
   FROM tpcds.web_sales ws
   JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE sm.sm_carrier = 'LATVIAN'
     AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
)
SELECT ca.c_customer_id,
       ca.c_first_name,
       ca.c_last_name,
       SUM(ca.net_profit)                                   AS total_net_profit,
       COUNT(*) FILTER (WHERE ca.channel = 'catalog')      AS catalog_orders,
       COUNT(*) FILTER (WHERE ca.channel = 'web')          AS web_orders
FROM (
   SELECT * FROM catalog_data
   UNION ALL
   SELECT * FROM web_data
) ca
GROUP BY ca.c_customer_id, ca.c_first_name, ca.c_last_name
ORDER BY total_net_profit DESC
LIMIT 20
