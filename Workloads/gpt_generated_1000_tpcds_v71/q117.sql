WITH item_warehouse_year AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        w.w_warehouse_id,
        d.d_fy_year,
        SUM(inv.inv_quantity_on_hand) AS total_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE inv.inv_quantity_on_hand > 500
      AND d.d_fy_year = 1919
      AND ws.web_company_id IN (1, 2, 3)
    GROUP BY i.i_item_id, i.i_brand, w.w_warehouse_id, d.d_fy_year
    HAVING SUM(inv.inv_quantity_on_hand) > 1000
)
SELECT
    iwy.i_item_id,
    iwy.i_brand,
    iwy.w_warehouse_id,
    iwy.d_fy_year,
    iwy.total_qty,
    SUM(iwy.total_qty) OVER (PARTITION BY iwy.d_fy_year ORDER BY iwy.total_qty DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_qty_by_year,
    ROW_NUMBER() OVER (PARTITION BY iwy.d_fy_year ORDER BY iwy.total_qty DESC) AS qty_rank
FROM item_warehouse_year iwy
ORDER BY iwy.d_fy_year DESC, iwy.total_qty DESC
LIMIT 100
