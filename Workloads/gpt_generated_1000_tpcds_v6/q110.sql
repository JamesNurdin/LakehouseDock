WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_warehouse_sk,
        cr.cr_catalog_page_sk,
        cr.cr_reason_sk,
        cr.cr_fee,
        cr.cr_return_ship_cost
    FROM catalog_returns cr
    WHERE cr.cr_return_amount BETWEEN 20 AND 5000
      AND cr.cr_return_quantity >= 1
      AND cr.cr_fee < 100
      AND cr.cr_return_ship_cost > 0
      AND cr.cr_net_loss > 0
      AND cr.cr_returned_date_sk BETWEEN 2450900 AND 2451543
)
SELECT
    cp.cp_catalog_page_id,
    COALESCE(w.w_warehouse_name, 'UNKNOWN') AS warehouse_name,
    r.r_reason_desc,
    fr.cr_return_amount,
    fr.cr_return_quantity,
    fr.cr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(w.w_warehouse_name, 'UNKNOWN') ORDER BY fr.cr_return_amount DESC) AS rn_by_warehouse,
    RANK() OVER (ORDER BY fr.cr_return_amount DESC) AS overall_return_amount_rank,
    CASE
        WHEN fr.cr_return_amount > 3000 THEN 'High'
        WHEN fr.cr_return_amount > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS amount_category
FROM filtered_returns fr
JOIN catalog_page cp
    ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
LEFT JOIN warehouse w
    ON fr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cp.cp_department = 'Electronics'
  AND cp.cp_type = 'Catalog'
  AND r.r_reason_desc LIKE '%Did not%'
  AND w.w_state IN ('CA', 'NY', 'TX')
  AND cp.cp_end_date_sk > 2450900
  AND cp.cp_catalog_page_number BETWEEN 1 AND 100
ORDER BY overall_return_amount_rank ASC
LIMIT 100
