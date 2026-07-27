WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_call_center_sk,
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        cr.cr_returned_time_sk,
        sm.sm_carrier,
        td.t_hour
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
)

SELECT entity_type,
       entity_name,
       total_return_amount,
       amount_category
FROM (
    SELECT
        'CallCenter' AS entity_type,
        cc.cc_name AS entity_name,
        SUM(b.cr_return_amount) AS total_return_amount,
        CASE WHEN SUM(b.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM base b
    JOIN call_center cc ON b.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'
      AND b.sm_carrier = 'UPS'
      AND b.t_hour BETWEEN 9 AND 17
    GROUP BY cc.cc_name

    UNION ALL

    SELECT
        'Warehouse' AS entity_type,
        w.w_warehouse_name AS entity_name,
        SUM(b.cr_return_amount) AS total_return_amount,
        CASE WHEN SUM(b.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM base b
    JOIN warehouse w ON b.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'TX'
      AND b.sm_carrier = 'PRIVATECARRIER'
      AND b.t_hour BETWEEN 0 AND 8
    GROUP BY w.w_warehouse_name
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
