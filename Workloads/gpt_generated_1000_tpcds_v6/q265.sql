WITH filtered_returns AS (
    SELECT
        cr_returned_time_sk,
        cr_catalog_page_sk,
        cr_ship_mode_sk,
        cr_reason_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_return_tax,
        cr_net_loss,
        cr_order_number
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_return_amount > 10.00
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    r.r_reason_desc,
    sm.sm_type,
    td.t_meal_time,
    COUNT(DISTINCT fr.cr_order_number) AS orders_returned,
    SUM(fr.cr_return_quantity) AS total_quantity,
    SUM(fr.cr_return_amount) AS total_amount,
    AVG(fr.cr_return_amount) AS avg_amount,
    SUM(CASE WHEN sm.sm_type = 'EXPRESS' THEN fr.cr_return_amount ELSE 0 END) AS express_return_amount,
    COALESCE(SUM(fr.cr_net_loss), 0) AS total_net_loss
FROM filtered_returns fr
JOIN catalog_page cp
    ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td
    ON fr.cr_returned_time_sk = td.t_time_sk
LEFT JOIN ship_mode sm
    ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
WHERE cp.cp_department = 'Electronics'
  AND td.t_meal_time = 'lunch'
  AND r.r_reason_desc LIKE '%warranty%'
  AND (sm.sm_type = 'EXPRESS' OR sm.sm_type IS NULL)
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_department,
    r.r_reason_desc,
    sm.sm_type,
    td.t_meal_time
ORDER BY total_amount DESC
LIMIT 100
