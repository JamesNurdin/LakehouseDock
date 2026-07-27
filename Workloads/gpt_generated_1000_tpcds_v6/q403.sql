WITH warehouse_filtered AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_id,
        w_warehouse_name,
        w_zip,
        w_city,
        w_warehouse_sq_ft,
        regexp_extract(w_zip, '(\\d{3})') AS zip_prefix
    FROM tpcds.warehouse
    WHERE regexp_like(w_warehouse_id, '^AAAAAAA[AB]')
      AND w_city LIKE '%York%'
)
SELECT
    wf.w_warehouse_id,
    wf.w_warehouse_name,
    wf.zip_prefix,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    SUM(i.inv_quantity_on_hand) AS total_qty,
    AVG(i.inv_quantity_on_hand) AS avg_qty_per_item
FROM warehouse_filtered wf
JOIN tpcds.inventory i
    ON i.inv_warehouse_sk = wf.w_warehouse_sk
WHERE i.inv_quantity_on_hand > (
        SELECT AVG(inv_quantity_on_hand) * 0.5
        FROM tpcds.inventory
        WHERE inv_warehouse_sk = wf.w_warehouse_sk
    )
GROUP BY wf.w_warehouse_id, wf.w_warehouse_name, wf.zip_prefix
HAVING SUM(i.inv_quantity_on_hand) > 2000
ORDER BY total_qty DESC
LIMIT 10
