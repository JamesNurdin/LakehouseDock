WITH warehouse_inventory AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT
    r.r_reason_desc,
    sm_ret.sm_carrier AS return_carrier,
    w_ret.w_warehouse_name AS return_warehouse,
    wi.total_on_hand,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_net_paid) AS total_sales_amount,
    AVG(cs.cs_quantity) AS avg_quantity_per_sale
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm_ret
    ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN warehouse w_ret
    ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
JOIN ship_mode sm_sales
    ON cs.cs_ship_mode_sk = sm_sales.sm_ship_mode_sk
JOIN warehouse w_sales
    ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
JOIN warehouse_inventory wi
    ON wi.inv_warehouse_sk = w_ret.w_warehouse_sk
WHERE EXISTS (
    SELECT 1 FROM (
        SELECT DISTINCT p.p_promo_sk
        FROM promotion p
        WHERE p.p_discount_active = 'Y'
    ) promo_active
    WHERE promo_active.p_promo_sk = cs.cs_promo_sk
)
GROUP BY r.r_reason_desc, sm_ret.sm_carrier, w_ret.w_warehouse_name, wi.total_on_hand
ORDER BY total_return_amount DESC
LIMIT 100
