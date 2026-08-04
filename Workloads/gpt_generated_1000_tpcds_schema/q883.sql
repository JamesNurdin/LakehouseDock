WITH ship_sales AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        COUNT(*) AS order_cnt,
        MIN(d.d_date) AS first_ship_date
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND cs.cs_item_sk IN (
          SELECT inv.inv_item_sk
          FROM inventory inv
          WHERE inv.inv_quantity_on_hand > 600
      )
    GROUP BY cs.cs_ship_mode_sk, cs.cs_warehouse_sk
)
SELECT
    sm.sm_ship_mode_id               AS ship_mode_id,
    w.w_warehouse_name               AS warehouse_name,
    ss.total_net_paid                AS total_net_paid,
    ss.order_cnt                     AS order_cnt,
    inv_q.latest_inventory_qty       AS latest_inventory_qty,
    'ship_sales'                     AS source
FROM ship_sales ss
JOIN ship_mode sm ON ss.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ss.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN LATERAL (
    SELECT i.inv_quantity_on_hand AS latest_inventory_qty
    FROM inventory i
    JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
    WHERE i.inv_warehouse_sk = ss.cs_warehouse_sk
      AND d2.d_date = ss.first_ship_date
    ORDER BY i.inv_quantity_on_hand DESC
    LIMIT 1
) inv_q ON TRUE
UNION ALL
SELECT
    sm.sm_ship_mode_id               AS ship_mode_id,
    w.w_warehouse_name               AS warehouse_name,
    ss2.total_net_paid                AS total_net_paid,
    ss2.order_cnt                     AS order_cnt,
    NULL                              AS latest_inventory_qty,
    'store_closed'                    AS source
FROM (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
    GROUP BY cs.cs_ship_mode_sk, cs.cs_warehouse_sk
) ss2
JOIN ship_mode sm ON ss2.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ss2.cs_warehouse_sk = w.w_warehouse_sk
ORDER BY total_net_paid DESC
OFFSET 0
LIMIT 100
