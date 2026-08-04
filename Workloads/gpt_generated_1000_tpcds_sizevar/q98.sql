WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        i.i_item_id,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ca.ca_state,
        p.p_promo_id,
        w.w_warehouse_name,
        sm.sm_ship_mode_id,
        r.r_reason_desc,
        ws.ws_order_number,
        we.web_name,
        sm_ws.sm_ship_mode_id AS ws_ship_mode,
        w_ws.w_warehouse_name AS ws_warehouse,
        p_ws.p_promo_id AS ws_promo,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    FULL OUTER JOIN promotion p_full ON p_full.p_item_sk = i.i_item_sk
    CROSS JOIN (SELECT 'X' AS dummy) AS cross_dummy
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    LEFT JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    LEFT JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    LEFT JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT
    ca_state,
    r_reason_desc,
    COUNT(DISTINCT ss_ticket_number) AS orders,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand
FROM sales_base
WHERE NOT EXISTS (
    SELECT 1 FROM catalog_returns cr2
    WHERE cr2.cr_order_number = sales_base.ss_ticket_number
)
GROUP BY ca_state, r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
