WITH base AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        cs.cs_order_number,
        ss.ss_ticket_number,
        ws.ws_order_number,
        cs.cs_net_paid,
        ss.ss_net_paid,
        ws.ws_net_paid,
        sr.sr_fee,
        sm_cs.sm_code,
        sm_cs.sm_carrier,
        w.w_warehouse_sk,
        -- scalar subquery for inventory information
        (SELECT MAX(inv.inv_quantity_on_hand)
         FROM inventory inv
         WHERE inv.inv_warehouse_sk = w.w_warehouse_sk) AS max_inventory_on_hand,
        -- window ranking per promotion
        DENSE_RANK() OVER (
            PARTITION BY p.p_promo_id
            ORDER BY (cs.cs_net_paid + ss.ss_net_paid + ws.ws_net_paid) DESC
        ) AS promo_rank
    FROM store_sales ss
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_hdemo_sk = hd_ss.hd_demo_sk  -- using same household dimension as store_sales
    JOIN household_demographics hd_cs
        ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd_ss.hd_demo_sk
    JOIN household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE sm_cs.sm_code = 'AIR'
      AND sm_cs.sm_carrier = 'FEDEX'
      AND p.p_channel_dmail = 'Y'
      AND p.p_channel_radio = 'N'
      AND sr.sr_fee > 50
      AND ws.ws_quantity > 1
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = cs.cs_item_sk
            AND cs2.cs_net_paid > 5000
      )
)
SELECT
    p_promo_id,
    p_promo_name,
    cs_order_number,
    ss_ticket_number,
    ws_order_number,
    cs_net_paid,
    ss_net_paid,
    ws_net_paid,
    sr_fee,
    max_inventory_on_hand,
    promo_rank
FROM base
ORDER BY promo_rank, p_promo_id
LIMIT 100
