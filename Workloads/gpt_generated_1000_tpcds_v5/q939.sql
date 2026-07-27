WITH warehouse_stats AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_street_number,
        w.w_street_name,
        w.w_city,
        w.w_county,
        CONCAT(w.w_street_number, ' ', w.w_street_name) AS full_address,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS item_count
    FROM
        tpcds.warehouse w
        JOIN tpcds.inventory i
            ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        REGEXP_LIKE(w.w_street_name, '\\d+th')            -- e.g., "6th"
        AND w.w_city LIKE 'San%'
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_street_number,
        w.w_street_name,
        w.w_city,
        w.w_county,
        CONCAT(w.w_street_number, ' ', w.w_street_name)
)
SELECT
    ws.w_warehouse_name,
    ws.full_address,
    ws.w_city,
    ws.w_county,
    ws.total_qty,
    ws.item_count,
    CAST(REGEXP_EXTRACT(ws.w_street_name, '(\\d+)') AS integer) AS street_number_extracted,
    ws.total_qty / avg_qty.avg_quantity AS qty_vs_avg
FROM
    warehouse_stats ws
    CROSS JOIN (
        SELECT AVG(total_qty) AS avg_quantity FROM warehouse_stats
    ) avg_qty
WHERE
    ws.total_qty > (SELECT AVG(inv_quantity_on_hand) FROM tpcds.inventory)
ORDER BY
    ws.total_qty DESC
LIMIT 100
