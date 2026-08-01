/*
  Goal: Compare per‑warehouse financial impact from catalog returns and web sales, excluding orders that have a matching return in the opposite channel, include current inventory on hand, deduplicate across the two sources, rank the results and return the top 100 warehouses.
*/
WITH first AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS total_amount,
        (
            SELECT SUM(inv.inv_quantity_on_hand)
            FROM inventory inv
            WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
        ) AS total_inventory_qty
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damaged%'
      AND cr.cr_return_amount > 100
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = cr.cr_order_number
      )
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_warehouse_sk
),
second AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        (
            SELECT SUM(inv.inv_quantity_on_hand)
            FROM inventory inv
            WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
        ) AS total_inventory_qty
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE wsit.web_name LIKE '%Shop%'
      AND ws.ws_ext_sales_price > 5000
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = ws.ws_order_number
      )
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_warehouse_sk
)
SELECT
    u.w_warehouse_id,
    u.w_warehouse_name,
    u.total_amount,
    u.total_inventory_qty,
    ROW_NUMBER() OVER (ORDER BY u.total_amount DESC) AS row_num
FROM (
    SELECT * FROM first
    UNION
    SELECT * FROM second
) u
ORDER BY u.total_amount DESC
LIMIT 100
