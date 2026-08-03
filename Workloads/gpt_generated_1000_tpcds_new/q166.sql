WITH
    returns_joined AS (
        SELECT
            cr.cr_order_number,
            cr.cr_net_loss,
            cr.cr_warehouse_sk,
            cr.cr_ship_mode_sk,
            cr.cr_item_sk,
            cr.cr_return_quantity,
            ws.w_warehouse_id,
            ws.w_city,
            ws.w_state,
            ws.w_suite_number,
            sm.sm_carrier,
            sm.sm_contract
        FROM catalog_returns cr
        INNER JOIN warehouse ws ON cr.cr_warehouse_sk = ws.w_warehouse_sk
        INNER JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE regexp_like(sm.sm_carrier, '^F.*')               -- carriers starting with 'F'
          AND ws.w_suite_number LIKE 'Suite %'               -- suite numbers like "Suite X"
    ),
    all_orders AS (
        SELECT cr_order_number FROM returns_joined
    ),
    high_loss_orders AS (
        SELECT cr_order_number FROM returns_joined WHERE cr_net_loss > 2000
    ),
    orders_without_high_loss AS (
        SELECT cr_order_number FROM all_orders
        EXCEPT
        SELECT cr_order_number FROM high_loss_orders
    )
SELECT
    concat(r.w_city, ', ', r.w_state) AS location,
    r.w_warehouse_id,
    count(DISTINCT r.cr_order_number) AS orders_count,
    sum(r.cr_net_loss) AS total_net_loss,
    avg(r.cr_net_loss) AS avg_loss_per_order,
    max(regexp_extract(r.sm_carrier, '^([A-Z]+)', 1)) AS carrier_prefix,
    (SELECT avg(cr_net_loss) FROM catalog_returns) AS overall_avg_net_loss
FROM returns_joined r
WHERE r.cr_order_number IN (SELECT cr_order_number FROM orders_without_high_loss)
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        WHERE cs.cs_order_number = r.cr_order_number
          AND cs.cs_item_sk = r.cr_item_sk
          AND cs.cs_quantity > r.cr_return_quantity
    )
GROUP BY concat(r.w_city, ', ', r.w_state), r.w_warehouse_id
ORDER BY total_net_loss DESC
LIMIT 20
