WITH store_agg AS (
   SELECT
       ca.ca_state AS state,
       'store' AS channel,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_net_profit) AS total_profit,
       CASE WHEN SUM(ss.ss_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
   FROM tpcds.store_sales ss
   JOIN tpcds.customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2451915 AND 2451925
   GROUP BY ca.ca_state
),
web_agg AS (
   SELECT
       ca.ca_state AS state,
       'web' AS channel,
       SUM(ws.ws_net_paid) AS total_net_paid,
       SUM(ws.ws_net_profit) AS total_profit,
       CASE WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
   FROM tpcds.web_sales ws
   JOIN tpcds.customer_address ca
     ON ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2451915 AND 2451925
   GROUP BY ca.ca_state
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY state, channel
