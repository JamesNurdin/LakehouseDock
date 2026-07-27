WITH high_price_items AS (
    SELECT DISTINCT i.i_item_sk,
           i.i_category,
           i.i_current_price
    FROM item i
    WHERE i.i_current_price > 50
)
SELECT DISTINCT
    city,
    category,
    metric_type,
    metric_value,
    metric_count
FROM (
    SELECT
        w.w_city AS city,
        hp.i_category AS category,
        'return_amount' AS metric_type,
        SUM(cr.cr_return_amount) AS metric_value,
        COUNT(DISTINCT cr.cr_order_number) AS metric_count
    FROM catalog_returns cr
    JOIN high_price_items hp ON cr.cr_item_sk = hp.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 100
    GROUP BY w.w_city, hp.i_category

    UNION ALL

    SELECT
        w.w_city AS city,
        i.i_category AS category,
        'inventory_qty' AS metric_type,
        SUM(inv.inv_quantity_on_hand) AS metric_value,
        COUNT(DISTINCT i.i_item_sk) AS metric_count
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_quantity_on_hand > 500
    GROUP BY w.w_city, i.i_category
) AS combined
ORDER BY city, category, metric_type
LIMIT 100
