WITH base AS (
    SELECT
        i.i_category,
        w.w_state,
        sm.sm_type,
        cd.cd_gender,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ws.ws_net_paid_inc_tax,
        sr.sr_return_quantity,
        wr.wr_return_quantity,
        inv.inv_quantity_on_hand,
        c.c_customer_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk AND cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p3 ON cs.cs_promo_sk = p3.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_brand = 'Brand#23'
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND i.i_current_price > 500.00
      AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_customer_sk = c.c_customer_sk
              AND sr2.sr_return_quantity > 5
        )
)
SELECT
    i_category,
    w_state,
    sm_type,
    cd_gender,
    COUNT(DISTINCT ss_ticket_number) AS num_store_sales,
    SUM(ss_net_paid) AS total_store_net_paid,
    AVG(ws_net_paid_inc_tax) AS avg_web_net_paid_inc_tax,
    SUM(CASE WHEN sr_return_quantity > 0 THEN sr_return_quantity ELSE 0 END) AS total_store_returns_qty,
    SUM(CASE WHEN wr_return_quantity > 0 THEN wr_return_quantity ELSE 0 END) AS total_web_returns_qty,
    MIN(inv_quantity_on_hand) AS min_inventory_qty,
    MAX(inv_quantity_on_hand) AS max_inventory_qty
FROM base
GROUP BY i_category, w_state, sm_type, cd_gender
ORDER BY total_store_net_paid DESC
LIMIT 100
