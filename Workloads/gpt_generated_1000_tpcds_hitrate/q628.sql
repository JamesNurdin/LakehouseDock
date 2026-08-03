WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_tax,
        cr.cr_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 1
      AND cr.cr_returned_date_sk IN (
          SELECT d.d_date_sk
          FROM date_dim d
          WHERE d.d_year BETWEEN 2000 AND 2002
      )
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm
          WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
            AND sm.sm_type = 'OVERNIGHT'
      )
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_brand,
    i.i_class_id,
    cp.cp_catalog_number,
    sm.sm_type,
    w.w_warehouse_name,
    fr.cr_return_amount,
    CASE
        WHEN fr.cr_return_amount > 500 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS return_severity,
    AVG(fr.cr_return_amount) OVER (PARTITION BY w.w_warehouse_id) AS avg_return_amount_by_warehouse,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY fr.cr_return_amount DESC) AS warehouse_rn
FROM filtered_returns fr
JOIN date_dim d
    ON fr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON fr.cr_item_sk = i.i_item_sk
FULL OUTER JOIN ship_mode sm
    ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
       AND (sm.sm_type = 'OVERNIGHT' OR sm.sm_type IS NULL)
JOIN catalog_page cp
    ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON fr.cr_warehouse_sk = w.w_warehouse_sk
WHERE i.i_class_id IN (4, 7, 13, 14)
  AND w.w_state = 'CA'
ORDER BY w.w_warehouse_name, fr.cr_return_amount DESC
LIMIT 100
