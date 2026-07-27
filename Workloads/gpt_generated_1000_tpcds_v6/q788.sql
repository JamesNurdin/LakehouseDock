/*
Goal: Compare sales performance and return losses for orders shipped via the USPS carrier during Evening shifts, limited to warehouses located in California. The query reports sales and return records side‑by‑side, includes a warehouse‑level average discount/return amount as a scalar subquery, and orders the combined result by record type and net amount.
*/
WITH ca_warehouses AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_id,
        w_state
    FROM warehouse
    WHERE w_state = 'CA'
)
SELECT
    'sale' AS record_type,
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    sm.sm_carrier,
    w.w_warehouse_id,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    (
        SELECT AVG(cs2.cs_ext_discount_amt)
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
    ) AS avg_discount_warehouse
FROM catalog_sales cs
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN ca_warehouses w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
WHERE sm.sm_carrier = 'USPS'
  AND t.t_shift = 'Evening'

UNION ALL

SELECT
    'return' AS record_type,
    cr.cr_order_number AS cs_order_number,
    cr.cr_returned_date_sk AS cs_sold_date_sk,
    sm.sm_carrier,
    w.w_warehouse_id,
    cr.cr_return_quantity AS cs_quantity,
    cr.cr_return_amount AS cs_net_paid,
    cr.cr_net_loss AS cs_net_profit,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
    ) AS avg_discount_warehouse
FROM catalog_returns cr
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN ca_warehouses w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
WHERE sm.sm_carrier = 'USPS'
  AND t.t_shift = 'Evening'

ORDER BY record_type, cs_net_paid DESC
LIMIT 100
