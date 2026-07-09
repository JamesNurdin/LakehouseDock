WITH store_closed_counts AS (
    SELECT
        d.d_date_sk AS closed_date_sk,
        COUNT(DISTINCT s.s_store_id) AS closed_store_cnt
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
),
warehouse_inventory_totals AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        SUM(inv.inv_quantity_on_hand) * 1.0 / NULLIF(w.w_warehouse_sq_ft, 0) AS qty_per_sq_ft
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY inv.inv_warehouse_sk, w.w_warehouse_sq_ft
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc_open.d_year AS open_year,
    cc_closed.d_year AS closed_year,
    (cc_closed.d_year - cc_open.d_year) AS years_active,
    w.w_warehouse_id,
    w.w_city AS warehouse_city,
    w.w_warehouse_sq_ft,
    inv.inv_item_sk,
    inv.inv_quantity_on_hand,
    wi.total_qty AS total_qty_at_warehouse,
    wi.qty_per_sq_ft,
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    sc.closed_store_cnt,
    SUM(inv.inv_quantity_on_hand) OVER (PARTITION BY w.w_warehouse_sk) AS running_qty_by_warehouse,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY inv.inv_quantity_on_hand DESC) AS inventory_rank_by_qty
FROM call_center cc
JOIN date_dim cc_open ON cc.cc_open_date_sk = cc_open.d_date_sk
JOIN date_dim cc_closed ON cc.cc_closed_date_sk = cc_closed.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = cc_open.d_date_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store s ON s.s_closed_date_sk = cc_closed.d_date_sk
JOIN store_closed_counts sc ON sc.closed_date_sk = cc_closed.d_date_sk
JOIN warehouse_inventory_totals wi ON wi.inv_warehouse_sk = w.w_warehouse_sk
WHERE inv.inv_quantity_on_hand > 0
ORDER BY cc.cc_call_center_id, inv.inv_quantity_on_hand DESC
LIMIT 100
