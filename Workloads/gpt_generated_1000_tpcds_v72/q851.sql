WITH base AS (
    SELECT
        s.s_store_id,
        t.t_time,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(CASE WHEN i.i_color = 'Red' THEN 1 ELSE 0 END) AS red_item_count,
        SUM(ia.total_on_hand) AS total_inventory_on_hand
    FROM
        catalog_sales cs
        INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
        INNER JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
        INNER JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                                   AND sr.sr_item_sk = i.i_item_sk
        INNER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        INNER JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        INNER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_item_sk = i.i_item_sk
        INNER JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        INNER JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        INNER JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                   AND wr.wr_item_sk = i.i_item_sk
        CROSS JOIN LATERAL (
            SELECT SUM(inv.inv_quantity_on_hand) AS total_on_hand
            FROM inventory inv
            WHERE inv.inv_item_sk = i.i_item_sk
              AND inv.inv_warehouse_sk = w.w_warehouse_sk
        ) ia
    WHERE
        t.t_time = 10
        AND i.i_brand = 'Brand1'
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
    GROUP BY GROUPING SETS (
        (s.s_store_id, t.t_time),
        (s.s_store_id),
        (t.t_time),
        ()
    )
)
SELECT
    s_store_id,
    t_time,
    total_sales,
    total_return_loss,
    total_web_sales,
    total_catalog_return_loss,
    distinct_tickets,
    red_item_count,
    total_inventory_on_hand,
    SUM(total_sales) OVER (PARTITION BY s_store_id) AS sales_by_store,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS sales_rank
FROM base
ORDER BY s_store_id, t_time
LIMIT 100
