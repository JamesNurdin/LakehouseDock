WITH
  cr_data AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_warehouse_sk,
      cr.cr_ship_mode_sk,
      cr.cr_call_center_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cc.cc_name,
      w.w_warehouse_name,
      sm.sm_type,
      t.t_sub_shift,
      t.t_hour
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND t.t_sub_shift = 'morning'
      AND cr.cr_return_amount > 100
  ),
  ws_data AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_warehouse_sk,
      ws.ws_ship_mode_sk,
      ws.ws_promo_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      p.p_promo_name,
      w.w_warehouse_name AS ws_warehouse_name,
      sm.sm_type AS ws_sm_type,
      t.t_sub_shift AS ws_sub_shift,
      t.t_hour AS ws_hour
    FROM web_sales ws
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND t.t_sub_shift = 'morning'
      AND ws.ws_net_paid > 200
  ),
  missing_wh AS (
    SELECT inv_warehouse_sk
    FROM inventory
    EXCEPT
    SELECT ws_warehouse_sk
    FROM web_sales
  ),
  cross_vals AS (
    SELECT * FROM (VALUES (1), (2), (3)) AS v(val)
  )
SELECT
  COALESCE(cr.cc_name, 'No Call Center') AS call_center_name,
  COALESCE(ws.p_promo_name, 'No Promo') AS promo_name,
  COALESCE(cr.w_warehouse_name, ws.ws_warehouse_name) AS warehouse_name,
  COALESCE(cr.sm_type, ws.ws_sm_type) AS ship_mode_type,
  cr.t_sub_shift AS return_shift,
  ws.ws_sub_shift AS sales_shift,
  SUM(cr.cr_return_quantity) AS total_return_qty,
  SUM(ws.ws_quantity) AS total_sales_qty,
  SUM(ws.ws_net_paid) AS total_net_paid,
  COUNT(DISTINCT cr.cr_returned_date_sk) AS distinct_return_days,
  COUNT(DISTINCT ws.ws_sold_date_sk) AS distinct_sales_days,
  cv.val AS cross_val
FROM cr_data cr
FULL OUTER JOIN ws_data ws
  ON cr.cr_warehouse_sk = ws.ws_warehouse_sk
 AND cr.cr_ship_mode_sk = ws.ws_ship_mode_sk
LEFT JOIN inventory inv
  ON COALESCE(cr.cr_warehouse_sk, ws.ws_warehouse_sk) = inv.inv_warehouse_sk
CROSS JOIN cross_vals cv
WHERE NOT EXISTS (
        SELECT 1
        FROM missing_wh mw
        WHERE mw.inv_warehouse_sk = COALESCE(cr.cr_warehouse_sk, ws.ws_warehouse_sk)
      )
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ws.ws_promo_sk
          AND p.p_start_date_sk <= ws.ws_sold_date_sk
          AND p.p_end_date_sk >= ws.ws_sold_date_sk
      )
GROUP BY
  COALESCE(cr.cc_name, 'No Call Center'),
  COALESCE(ws.p_promo_name, 'No Promo'),
  COALESCE(cr.w_warehouse_name, ws.ws_warehouse_name),
  COALESCE(cr.sm_type, ws.ws_sm_type),
  cr.t_sub_shift,
  ws.ws_sub_shift,
  cv.val
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100
