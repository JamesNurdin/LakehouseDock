WITH wh_inventory AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk,
        inv.inv_warehouse_sk,
        wh.w_warehouse_sk,
        wh.w_warehouse_name,
        wh.w_state,
        wh.w_gmt_offset,
        ARRAY[wh.w_street_number, wh.w_street_name, wh.w_street_type] AS addr_parts
    FROM inventory inv
    FULL OUTER JOIN warehouse wh
        ON inv.inv_warehouse_sk = wh.w_warehouse_sk
)
SELECT
    d.d_year,
    d.d_quarter_name,
    whinv.w_warehouse_name,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_items,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(CASE WHEN d.d_weekend = 'Y' THEN cr.cr_return_amount END) AS avg_weekend_return,
    MIN(cr.cr_return_ship_cost) AS min_ship_cost,
    MAX(cr.cr_return_ship_cost) AS max_ship_cost,
    SUM(CASE WHEN cr.cr_return_amount > 500 THEN 1 ELSE 0 END) AS high_value_returns,
    COUNT(*) FILTER (WHERE cr.cr_return_quantity > 2) AS returns_qty_gt_2,
    SUM(length(addr_part)) AS total_addr_part_len
FROM catalog_returns cr
RIGHT OUTER JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN wh_inventory whinv
    ON cr.cr_warehouse_sk = whinv.w_warehouse_sk
CROSS JOIN UNNEST(whinv.addr_parts) AS t (addr_part)
WHERE d.d_year = 2001
  AND d.d_quarter_name = 'Q1'
  AND whinv.w_state = 'TX'
  AND cr.cr_return_amount > 100
  AND cr.cr_return_quantity BETWEEN 1 AND 5
  AND whinv.inv_quantity_on_hand < 500
  AND whinv.w_gmt_offset BETWEEN -5 AND 0
GROUP BY d.d_year, d.d_quarter_name, whinv.w_warehouse_name
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
