WITH catalog_agg AS (
  SELECT
    cp.cp_department,
    sm.sm_ship_mode_id,
    d.d_year,
    d.d_moy AS month,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND cp.cp_type = 'monthly'
  GROUP BY cp.cp_department, sm.sm_ship_mode_id, d.d_year, d.d_moy
),
sales_agg AS (
  SELECT
    sm.sm_ship_mode_id,
    d.d_year,
    d.d_moy AS month,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity
  FROM web_sales ws
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND ws.ws_quantity > 0
  GROUP BY sm.sm_ship_mode_id, d.d_year, d.d_moy
),
inventory_agg AS (
  SELECT
    d.d_year,
    d.d_moy AS month,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
  FROM inventory inv
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_moy
)
SELECT
  ca.cp_department,
  ca.sm_ship_mode_id,
  ca.d_year,
  ca.month,
  ca.total_net_loss,
  sa.total_net_profit,
  CASE WHEN sa.total_net_profit <> 0 THEN ca.total_net_loss / sa.total_net_profit ELSE NULL END AS loss_to_profit_ratio,
  ca.return_cnt,
  ia.avg_inventory_qty
FROM catalog_agg ca
JOIN sales_agg sa
  ON ca.sm_ship_mode_id = sa.sm_ship_mode_id
  AND ca.d_year = sa.d_year
  AND ca.month = sa.month
LEFT JOIN inventory_agg ia
  ON ca.d_year = ia.d_year
  AND ca.month = ia.month
WHERE ca.return_cnt > 100
ORDER BY ca.total_net_loss DESC
LIMIT 20
