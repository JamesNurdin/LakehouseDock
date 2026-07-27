WITH high_qty_warehouses AS (
    SELECT w.w_warehouse_sk
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 800
)
SELECT
    r.r_reason_desc AS reason,
    'Catalog' AS source,
    SUM(cr.cr_net_loss) AS total_loss,
    CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS avg_loss
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE w.w_warehouse_sk IN (SELECT w_warehouse_sk FROM high_qty_warehouses)
GROUP BY r.r_reason_desc

UNION ALL

SELECT
    r.r_reason_desc AS reason,
    'Web' AS source,
    SUM(wr.wr_net_loss) AS total_loss,
    CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    (SELECT AVG(wr2.wr_net_loss) FROM web_returns wr2) AS avg_loss
FROM web_returns wr
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_warehouse_sk IN (SELECT w_warehouse_sk FROM high_qty_warehouses)
GROUP BY r.r_reason_desc
ORDER BY total_loss DESC
LIMIT 100
