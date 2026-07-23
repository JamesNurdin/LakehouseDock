WITH filtered_store AS (
    SELECT *
    FROM store
    WHERE s_state = 'CA'
      AND s_number_employees >= 100
),
filtered_ship AS (
    SELECT *
    FROM ship_mode
    WHERE sm_type = 'AIR'
),
filtered_reason AS (
    SELECT *
    FROM reason
    WHERE r_reason_desc LIKE '%price%'
),
filtered_inventory AS (
    SELECT *
    FROM inventory
    WHERE inv_quantity_on_hand > 500
),
filtered_catalog_page AS (
    SELECT *
    FROM catalog_page
    WHERE cp_department = 'Electronics'
),
filtered_time AS (
    SELECT *
    FROM time_dim
    WHERE t_hour BETWEEN 9 AND 17
)
SELECT
    final.s_store_id,
    final.sm_ship_mode_id,
    final.r_reason_id,
    final.cp_department,
    final.total_catalog_net_paid,
    final.total_store_net_paid,
    final.catalog_orders,
    final.store_tickets,
    final.avg_catalog_profit,
    final.max_store_tax,
    RANK() OVER (PARTITION BY final.sm_ship_mode_id ORDER BY final.total_catalog_net_paid DESC) AS ship_mode_store_rank,
    final.avg_warehouse_inventory
FROM (
    SELECT
        s.s_store_id,
        sm.sm_ship_mode_id,
        r.r_reason_id,
        cp.cp_department,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
        AVG(cs.cs_net_profit) AS avg_catalog_profit,
        MAX(ss.ss_ext_tax) AS max_store_tax,
        (SELECT AVG(inv2.inv_quantity_on_hand)
         FROM inventory inv2
         WHERE inv2.inv_warehouse_sk = w.w_warehouse_sk) AS avg_warehouse_inventory,
        w.w_warehouse_sk
    FROM filtered_catalog_page cp
    JOIN catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN filtered_ship sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN filtered_time t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN filtered_reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN filtered_inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN filtered_store s
        ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        s.s_store_id,
        sm.sm_ship_mode_id,
        r.r_reason_id,
        cp.cp_department,
        w.w_warehouse_sk
) final
ORDER BY final.total_catalog_net_paid DESC
LIMIT 100
