WITH inventory_summary AS (
    SELECT
        i.i_item_sk,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        MAX(i.i_current_price) AS current_price,
        CASE
            WHEN i.i_size = 'large' THEN 'LARGE_SIZE'
            WHEN i.i_size = 'medium' THEN 'MEDIUM_SIZE'
            ELSE 'OTHER_SIZE'
        END AS size_category
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY i.i_item_sk, w.w_warehouse_sk, w.w_warehouse_name, i.i_size
)
SELECT
    'PROMO' AS source_type,
    isum.w_warehouse_name,
    isum.size_category,
    SUM(isum.total_qty * isum.current_price) AS revenue_estimate,
    COUNT(DISTINCT isum.i_item_sk) AS distinct_items
FROM inventory_summary isum
JOIN promotion p ON p.p_item_sk = isum.i_item_sk
WHERE p.p_discount_active = 'Y'
  AND p.p_end_date_sk > 2450800
GROUP BY isum.w_warehouse_name, isum.size_category

UNION ALL

SELECT
    'NO_PROMO' AS source_type,
    isum.w_warehouse_name,
    isum.size_category,
    SUM(isum.total_qty * isum.current_price) AS revenue_estimate,
    COUNT(DISTINCT isum.i_item_sk) AS distinct_items
FROM inventory_summary isum
LEFT JOIN promotion p ON p.p_item_sk = isum.i_item_sk
    AND p.p_discount_active = 'Y'
    AND p.p_end_date_sk > 2450800
WHERE p.p_item_sk IS NULL
GROUP BY isum.w_warehouse_name, isum.size_category
ORDER BY source_type, revenue_estimate DESC
LIMIT 100
