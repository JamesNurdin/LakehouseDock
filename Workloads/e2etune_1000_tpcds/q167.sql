WITH catalog AS (
  SELECT
    ca.ca_city AS bill_city,
    ca.ca_state AS bill_state,
    cs.cs_net_profit AS profit,
    cs.cs_quantity AS qty,
    'catalog' AS channel,
    cs.cs_sold_date_sk AS sold_date_sk,
    cs.cs_ship_mode_sk AS ship_mode_sk,
    cs.cs_call_center_sk AS call_center_sk,
    cs.cs_catalog_page_sk AS catalog_page_sk
  FROM catalog_sales cs
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    AND cc.cc_city = 'Greenwood'
),
web AS (
  SELECT
    ca.ca_city AS bill_city,
    ca.ca_state AS bill_state,
    ws.ws_net_profit AS profit,
    ws.ws_quantity AS qty,
    'web' AS channel,
    ws.ws_sold_date_sk AS sold_date_sk,
    ws.ws_ship_mode_sk AS ship_mode_sk,
    NULL AS call_center_sk,
    NULL AS catalog_page_sk
  FROM web_sales ws
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    AND ca.ca_state = 'CA'
)
SELECT
  channel,
  bill_city,
  bill_state,
  SUM(profit) AS total_profit,
  SUM(qty) AS total_quantity,
  RANK() OVER (PARTITION BY channel ORDER BY SUM(profit) DESC) AS profit_rank
FROM (
  SELECT * FROM catalog
  UNION ALL
  SELECT * FROM web
) t
GROUP BY channel, bill_city, bill_state
HAVING SUM(profit) > 0
ORDER BY channel, profit_rank
LIMIT 100
