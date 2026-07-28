-- goal: Analyze combined catalog and web sales profitability by department and store, including return losses, inventory context, and ranking.
WITH aggregated_data AS (
    SELECT
        cp.cp_department,
        s.s_store_name,
        w1.w_warehouse_sk,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
        SUM(cs.cs_quantity) AS total_quantity,
        (
            SELECT AVG(inv2.inv_quantity_on_hand)
            FROM inventory inv2
            WHERE inv2.inv_warehouse_sk = w1.w_warehouse_sk
        ) AS avg_inventory_qty
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w1
        ON cs.cs_warehouse_sk = w1.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w1.w_warehouse_sk
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w1.w_warehouse_sk
    JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_web_creation
        ON wp.wp_creation_date_sk = d_web_creation.d_date_sk
    JOIN date_dim d_web_access
        ON wp.wp_access_date_sk = d_web_access.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN date_dim d_page_start
        ON cp.cp_start_date_sk = d_page_start.d_date_sk
    JOIN date_dim d_page_end
        ON cp.cp_end_date_sk = d_page_end.d_date_sk
    GROUP BY ROLLUP (cp.cp_department, s.s_store_name, w1.w_warehouse_sk)
)
SELECT
    cp_department,
    s_store_name,
    total_catalog_profit,
    total_web_profit,
    total_return_loss,
    CASE WHEN total_quantity > 1000 THEN 'HIGH' ELSE 'LOW' END AS quantity_category,
    avg_inventory_qty,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_catalog_profit DESC) AS dept_rank
FROM aggregated_data
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr_check
    WHERE cr_check.cr_return_amount > 0
)
ORDER BY cp_department ASC, s_store_name ASC NULLS LAST, total_catalog_profit DESC
LIMIT 100
