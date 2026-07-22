WITH returns_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        MAX(cr.cr_returned_date_sk) AS max_return_date_sk,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Medium' END AS return_level
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450800 AND 2451100
      AND cr.cr_return_amount > 0
      AND cr.cr_return_quantity > 0
      AND cr.cr_fee < 100
      AND cr.cr_return_tax >= 0
      AND cr.cr_refunded_cash IS NOT NULL
      AND cr.cr_return_ship_cost >= 0
    GROUP BY cr.cr_warehouse_sk
),
inventory_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        COUNT(DISTINCT inv.inv_date_sk) AS distinct_dates,
        CASE WHEN SUM(inv.inv_quantity_on_hand) > 5000 THEN 'Large' ELSE 'Small' END AS inventory_size
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
      AND inv.inv_date_sk BETWEEN 2450800 AND 2451100
      AND inv.inv_warehouse_sk IS NOT NULL
      AND inv.inv_quantity_on_hand BETWEEN 600 AND 1000
      AND inv.inv_warehouse_sk IN (SELECT w.w_warehouse_sk FROM warehouse w WHERE w.w_county LIKE '%County%')
      AND inv.inv_warehouse_sk NOT IN (SELECT w.w_warehouse_sk FROM warehouse w WHERE w.w_gmt_offset = -7.00)
    GROUP BY inv.inv_warehouse_sk
)
SELECT DISTINCT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_county,
    r.total_return_amount,
    r.total_return_quantity,
    i.total_on_hand,
    r.return_level,
    i.inventory_size,
    RANK() OVER (PARTITION BY w.w_state ORDER BY r.total_return_amount DESC) AS state_return_rank,
    ROW_NUMBER() OVER (ORDER BY r.total_return_amount DESC) AS overall_rank
FROM returns_agg r
JOIN warehouse w ON r.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory_agg i ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_warehouse_sk = w.w_warehouse_sk
      AND inv2.inv_quantity_on_hand > 800
      AND inv2.inv_date_sk BETWEEN 2450800 AND 2451100
)
ORDER BY overall_rank
LIMIT 100
