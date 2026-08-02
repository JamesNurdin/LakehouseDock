WITH base AS (
    SELECT
        s.s_state,
        cd.cd_gender,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_net_paid) AS avg_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        (
            SELECT SUM(inv2.inv_quantity_on_hand)
            FROM inventory inv2
            JOIN warehouse w2 ON inv2.inv_warehouse_sk = w2.w_warehouse_sk
            WHERE w2.w_state = s.s_state
        ) AS state_total_inventory_qty
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE s.s_number_employees >= 260
      AND cs.cs_ext_tax > 100
      AND cd.cd_gender = 'F'
    GROUP BY GROUPING SETS (
        (s.s_state, cd.cd_gender),
        (s.s_state),
        (cd.cd_gender),
        ()
    )
)
SELECT
    s_state,
    cd_gender,
    total_net_paid,
    avg_net_paid,
    num_orders,
    CASE WHEN total_net_paid > 500000 THEN 'High' ELSE 'Low' END AS net_paid_category,
    state_total_inventory_qty,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn
FROM base
ORDER BY total_net_paid DESC
LIMIT 100
