WITH base_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cp.cp_department,
        sm.sm_ship_mode_id,
        sm.sm_ship_mode_sk,
        sm.sm_carrier,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_state,
        p.p_promo_id,
        p.p_cost,
        p.p_channel_demo,
        p.p_channel_radio,
        wp.wp_url,
        wp.wp_rec_start_date,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    WHERE
        sm.sm_ship_mode_sk = 8
        AND sm.sm_carrier = 'UPS'
        AND p.p_channel_demo = 'N'
        AND p.p_channel_radio = 'N'
        AND wp.wp_rec_start_date >= DATE '2000-01-01'
        AND wp.wp_rec_start_date < DATE '2001-01-01'
        AND cp.cp_department = 'Electronics'
)
SELECT
    base_data.cp_department,
    base_data.sm_carrier,
    SUM(base_data.cs_net_profit) AS total_catalog_net_profit,
    SUM(base_data.ws_net_profit) AS total_web_net_profit,
    SUM(COALESCE(base_data.cr_return_amount, 0)) AS total_catalog_return_amount,
    SUM(COALESCE(base_data.wr_return_amt, 0)) AS total_web_return_amount,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_quantity,
    (SELECT SUM(p_sub.p_cost) FROM promotion p_sub WHERE p_sub.p_channel_demo = 'N') AS total_demo_promo_cost,
    (SUM(base_data.cs_net_profit) + SUM(base_data.ws_net_profit) -
        (SELECT SUM(p_sub2.p_cost) FROM promotion p_sub2 WHERE p_sub2.p_channel_demo = 'N')) AS net_profit_adjusted
FROM base_data
FULL OUTER JOIN inventory inv ON inv.inv_warehouse_sk = base_data.w_warehouse_sk
WHERE (inv.inv_quantity_on_hand > 0 OR inv.inv_quantity_on_hand IS NULL)
GROUP BY ROLLUP (base_data.cp_department, base_data.sm_carrier)
ORDER BY total_catalog_net_profit DESC NULLS LAST, base_data.cp_department
LIMIT 100
