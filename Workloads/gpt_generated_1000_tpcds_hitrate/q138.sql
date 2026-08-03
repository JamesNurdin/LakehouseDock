WITH base AS (
  SELECT
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_return_amt_inc_tax,
    cr.cr_fee,
    cc.cc_manager,
    cp.cp_department,
    r.r_reason_desc,
    w1.w_warehouse_name        AS cr_warehouse_name,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_profit,
    w2.w_warehouse_name        AS ws_warehouse_name,
    inv1.inv_quantity_on_hand  AS inv_qty_cr_wh,
    inv2.inv_quantity_on_hand  AS inv_qty_ws_wh
  FROM catalog_returns cr
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w1
    ON cr.cr_warehouse_sk = w1.w_warehouse_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_sales ws
    ON ws.ws_warehouse_sk = w1.w_warehouse_sk
  JOIN warehouse w2
    ON ws.ws_warehouse_sk = w2.w_warehouse_sk
  JOIN inventory inv1
    ON inv1.inv_warehouse_sk = w1.w_warehouse_sk
  JOIN inventory inv2
    ON inv2.inv_warehouse_sk = w2.w_warehouse_sk
  WHERE cc.cc_class = 'large'
),
unioned AS (
  SELECT * FROM base WHERE r_reason_desc = 'Lost my job'
  UNION
  SELECT * FROM base WHERE r_reason_desc = 'Wrong size'
)
SELECT
  cr_warehouse_name,
  ws_warehouse_name,
  cc_manager,
  SUM(cr_return_amount)   AS total_return_amount,
  SUM(ws_net_profit)      AS total_net_profit,
  COUNT(*)                AS transaction_count
FROM unioned
GROUP BY
  cr_warehouse_name,
  ws_warehouse_name,
  cc_manager
ORDER BY total_return_amount DESC
LIMIT 100
