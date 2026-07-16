WITH agg AS (
  SELECT
    ca.ca_state AS state,
    sm.sm_type AS ship_type,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
    SUM(ws.ws_quantity) AS total_quantity,
    (SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_net_paid), 0)) AS profit_margin
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
    AND sm.sm_type = 'AIR'
    AND cd.cd_credit_rating = 'A'
    AND ca.ca_state IN ('CA','TX','NY')
  GROUP BY ca.ca_state, sm.sm_type
  HAVING SUM(ws.ws_net_paid) > 10000
)
SELECT
  state,
  ship_type,
  total_net_paid,
  total_profit,
  avg_discount,
  unique_customers,
  total_quantity,
  profit_margin,
  RANK() OVER (PARTITION BY state ORDER BY total_net_paid DESC) AS sales_rank_by_state
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
