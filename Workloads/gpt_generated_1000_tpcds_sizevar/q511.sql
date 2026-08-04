WITH cs AS (
  SELECT
    cs.cs_ship_mode_sk,
    sm.sm_type,
    cs.cs_net_paid,
    cs.cs_net_profit,
    ca.ca_state,
    d.d_fy_week_seq,
    cs.cs_bill_customer_sk
  FROM catalog_sales cs
  TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_fy_week_seq = 15
    AND EXISTS (
      SELECT 1 FROM inventory inv
      WHERE inv.inv_item_sk = cs.cs_item_sk
        AND inv.inv_date_sk = cs.cs_sold_date_sk
    )
),
ws AS (
  SELECT DISTINCT
    ws.ws_ship_mode_sk,
    sm.sm_type,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ca.ca_state,
    d.d_fy_week_seq,
    ws.ws_bill_customer_sk
  FROM web_sales ws
  TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_fy_week_seq = 15
)
SELECT
  c.sm_type,
  c.d_fy_week_seq,
  CASE WHEN SUM(c.net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
  SUM(c.net_paid) AS total_net_paid,
  COUNT(DISTINCT c.customer_sk) AS distinct_customers,
  (
    SELECT SUM(inv_quantity_on_hand)
    FROM inventory inv
    JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
    WHERE d2.d_fy_week_seq = c.d_fy_week_seq
  ) AS week_inventory_qty
FROM (
  SELECT
    cs_ship_mode_sk AS ship_mode_sk,
    sm_type,
    cs_net_paid AS net_paid,
    cs_net_profit AS net_profit,
    ca_state,
    d_fy_week_seq,
    cs_bill_customer_sk AS customer_sk
  FROM cs
  UNION ALL
  SELECT
    ws_ship_mode_sk,
    sm_type,
    ws_net_paid,
    ws_net_profit,
    ca_state,
    d_fy_week_seq,
    ws_bill_customer_sk
  FROM ws
) c
GROUP BY c.sm_type, c.d_fy_week_seq
ORDER BY total_net_paid DESC
LIMIT 100
