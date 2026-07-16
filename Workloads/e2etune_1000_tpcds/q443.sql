WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_country,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        AVG(i.inv_quantity_on_hand) AS avg_quantity,
        COUNT(*) FILTER (WHERE i.inv_quantity_on_hand < 0) AS negative_qty_rows
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
      AND i.inv_date_sk >= (SELECT MAX(inv_date_sk) - 30 FROM inventory)
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, w.w_state, w.w_country
    HAVING SUM(i.inv_quantity_on_hand) > 0
)
SELECT
    t.w_warehouse_name,
    t.w_city,
    t.w_state,
    t.total_quantity,
    t.distinct_items,
    t.avg_quantity,
    t.negative_qty_rows,
    t.state_rank
FROM (
    SELECT
        wi.w_warehouse_name,
        wi.w_city,
        wi.w_state,
        wi.total_quantity,
        wi.distinct_items,
        wi.avg_quantity,
        wi.negative_qty_rows,
        ROW_NUMBER() OVER (PARTITION BY wi.w_state ORDER BY wi.total_quantity DESC) AS state_rank
    FROM warehouse_inventory wi
) t
WHERE t.state_rank <= 5
ORDER BY t.w_state, t.state_rank
