WITH base AS (
    SELECT
        w.w_warehouse_id,
        sm1.sm_ship_mode_id,
        r_return.r_reason_desc,
        cs.cs_net_profit,
        ss.ss_net_profit,
        ws.ws_net_profit,
        cr.cr_net_loss,
        sr.sr_net_loss
    FROM warehouse w
    -- catalog side
    JOIN catalog_sales cs
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm1
        ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN customer c1
        ON cs.cs_bill_customer_sk = c1.c_customer_sk
    JOIN customer_demographics cd1
        ON cs.cs_bill_cdemo_sk = cd1.cd_demo_sk
    -- catalog returns (linked to the same catalog sale)
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    -- web side
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN customer c2
        ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2
        ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    -- inventory (just to bring the table into the join graph)
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    -- store side (joined through the same customer used by catalog sales)
    JOIN store_sales ss
        ON ss.ss_customer_sk = c1.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r_return
        ON sr.sr_reason_sk = r_return.r_reason_sk
    JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    WHERE w.w_state = 'CA'
      AND cp.cp_type = 'BROWSE'
      AND cd1.cd_credit_rating = 'Good'
      AND sm1.sm_carrier = 'EXPRESS'
      AND ws.ws_ext_list_price > 5000
),
agg AS (
    SELECT
        w_warehouse_id,
        sm_ship_mode_id,
        r_reason_desc,
        SUM(cs_net_profit)          AS catalog_profit,
        SUM(ss_net_profit)          AS store_profit,
        SUM(ws_net_profit)          AS web_profit,
        SUM(cr_net_loss)            AS catalog_return_loss,
        SUM(sr_net_loss)            AS store_return_loss,
        (SUM(cs_net_profit) + SUM(ss_net_profit) + SUM(ws_net_profit) -
         SUM(cr_net_loss) - SUM(sr_net_loss)) AS total_profit
    FROM base
    GROUP BY ROLLUP (w_warehouse_id, sm_ship_mode_id, r_reason_desc)
),
ranked AS (
    SELECT
        w_warehouse_id,
        sm_ship_mode_id,
        r_reason_desc,
        catalog_profit,
        store_profit,
        web_profit,
        total_profit,
        RANK() OVER (PARTITION BY w_warehouse_id ORDER BY total_profit DESC) AS rnk
    FROM agg
    WHERE w_warehouse_id IS NOT NULL   -- exclude the grand‑total row produced by ROLLUP
)
SELECT *
FROM (
    SELECT
        w_warehouse_id,
        sm_ship_mode_id,
        r_reason_desc,
        total_profit
    FROM ranked
    WHERE rnk <= 5

    UNION DISTINCT

    SELECT
        w_warehouse_id,
        sm_ship_mode_id,
        NULL AS r_reason_desc,
        total_profit
    FROM ranked
    WHERE sm_ship_mode_id IS NOT NULL AND rnk <= 3
) final_result
ORDER BY w_warehouse_id, total_profit DESC
LIMIT 100
