WITH base AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    cp.cp_description,
    cp.cp_type,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_returned_date_sk,
    r.r_reason_desc,
    cs.cs_quantity AS cs_quantity,
    cs.cs_net_paid_inc_ship AS cs_net_paid_inc_ship,
    cs.cs_net_profit AS cs_net_profit,
    ws.ws_quantity AS ws_quantity,
    ws.ws_net_paid_inc_ship AS ws_net_paid_inc_ship,
    ws.ws_net_profit AS ws_net_profit,
    w.w_warehouse_sk,
    w.w_warehouse_name,
    inv.inv_quantity_on_hand,
    inv.inv_date_sk
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_item_sk = cs.cs_item_sk
  JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_item_sk = cs.cs_item_sk
  WHERE cs.cs_net_paid_inc_ship > 1000
    AND ws.ws_net_paid_inc_ship < 5000
    AND inv.inv_quantity_on_hand > 0
    AND r.r_reason_desc LIKE '%Customer%'
),
unioned AS (
  SELECT
    w_warehouse_sk,
    w_warehouse_name,
    cp_department,
    cs_net_paid_inc_ship,
    ws_net_paid_inc_ship,
    (cs_net_paid_inc_ship + ws_net_paid_inc_ship) AS total_net_paid,
    cs_net_profit,
    ws_net_profit,
    inv_quantity_on_hand,
    'CS_GT_WS' AS source_flag
  FROM base
  WHERE cs_quantity > ws_quantity

  UNION ALL

  SELECT
    w_warehouse_sk,
    w_warehouse_name,
    cp_department,
    cs_net_paid_inc_ship,
    ws_net_paid_inc_ship,
    (cs_net_paid_inc_ship + ws_net_paid_inc_ship) AS total_net_paid,
    cs_net_profit,
    ws_net_profit,
    inv_quantity_on_hand,
    'WS_GE_CS' AS source_flag
  FROM base
  WHERE ws_quantity >= cs_quantity
)
SELECT
  w_warehouse_sk,
  w_warehouse_name,
  cp_department,
  source_flag,
  total_net_paid,
  inv_quantity_on_hand,
  RANK() OVER (PARTITION BY cp_department ORDER BY total_net_paid DESC) AS dept_rank,
  AVG(total_net_paid) OVER (PARTITION BY w_warehouse_sk) AS avg_warehouse_net_paid,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM catalog_returns cr2
      JOIN reason r2 ON cr2.cr_reason_sk = r2.r_reason_sk
      WHERE cr2.cr_warehouse_sk = unioned.w_warehouse_sk
        AND r2.r_reason_desc = 'Damaged'
    ) THEN 'Has Damaged Returns'
    ELSE 'No Damaged Returns'
  END AS damaged_return_flag
FROM unioned
WHERE total_net_paid > (
  SELECT AVG(cs_net_paid_inc_ship) FROM catalog_sales
)
ORDER BY total_net_paid DESC
LIMIT 100
