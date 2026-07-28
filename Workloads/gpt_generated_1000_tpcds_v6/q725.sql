WITH
  returns_cte AS (
    SELECT
      cr.cr_returned_date_sk AS event_date_sk,
      i.i_item_id,
      cr.cr_return_quantity AS quantity,
      cr.cr_return_amount AS amount,
      r.r_reason_desc AS reason_desc,
      sm.sm_type,
      (SELECT MAX(ws.ws_ext_sales_price)
         FROM web_sales ws
        WHERE ws.ws_item_sk = i.i_item_sk) AS metric_value,
      CASE WHEN EXISTS (
             SELECT 1
               FROM inventory inv
              WHERE inv.inv_item_sk = i.i_item_sk
                AND inv.inv_quantity_on_hand > 0)
           THEN 1 ELSE 0 END AS in_stock,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY cr.cr_returned_date_sk DESC) AS rn,
      'return' AS event_type
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_category = 'Sports'
      AND i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  ),
  sales_cte AS (
    SELECT
      ws.ws_sold_date_sk AS event_date_sk,
      i.i_item_id,
      ws.ws_quantity AS quantity,
      ws.ws_ext_sales_price AS amount,
      CAST(NULL AS varchar) AS reason_desc,
      sm.sm_type,
      (SELECT AVG(cr.cr_return_amount)
         FROM catalog_returns cr
        WHERE cr.cr_item_sk = i.i_item_sk) AS metric_value,
      CASE WHEN EXISTS (
             SELECT 1
               FROM inventory inv
              WHERE inv.inv_item_sk = i.i_item_sk
                AND inv.inv_quantity_on_hand > 0)
           THEN 1 ELSE 0 END AS in_stock,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_sold_date_sk DESC) AS rn,
      'sale' AS event_type
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_category = 'Sports'
      AND i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  )
SELECT
  event_date_sk,
  i_item_id,
  quantity,
  amount,
  reason_desc,
  sm_type,
  metric_value,
  in_stock,
  event_type
FROM (
  SELECT * FROM returns_cte
  UNION ALL
  SELECT * FROM sales_cte
) combined
WHERE rn = 1
ORDER BY event_date_sk DESC
LIMIT 100
