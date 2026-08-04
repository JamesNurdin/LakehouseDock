WITH
  reason_damage AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage')
  ),
  reason_defect AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%defect%'
  ),
  intersect_orders AS (
    SELECT cr_order_number FROM reason_damage
    INTERSECT
    SELECT cr_order_number FROM reason_defect
  ),
  union_orders AS (
    SELECT cr_order_number FROM reason_damage
    UNION
    SELECT cr_order_number FROM reason_defect
  ),
  except_orders AS (
    SELECT cr_order_number FROM reason_damage
    EXCEPT
    SELECT cr_order_number FROM reason_defect
  ),
  main AS (
    SELECT
      cr.cr_order_number,
      w.w_warehouse_name,
      w.w_city,
      w.w_state,
      r.r_reason_desc,
      cr.cr_return_amount,
      cr.cr_net_loss,
      CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category,
      regexp_extract(r.r_reason_desc, '(\\w+)$') AS last_word,
      (r.r_reason_desc || ' - ' || w.w_warehouse_name) AS reason_warehouse
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_order_number IN (SELECT cr_order_number FROM intersect_orders)
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_customer_sk = cr.cr_refunded_customer_sk
          AND cr2.cr_return_amount > 0
      )
      AND CONCAT(w.w_city, '-', w.w_state) LIKE '%York%'
  )
SELECT
  loss_category,
  COUNT(DISTINCT cr_order_number) AS orders_cnt,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(cr_net_loss) AS total_net_loss,
  ARRAY_AGG(DISTINCT reason_warehouse) AS reasons_warehouses
FROM main
GROUP BY loss_category
ORDER BY total_net_loss DESC
LIMIT 100
