WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_manager,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_transactions,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_catalog_return_amount,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_return_loss
    FROM store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE s.s_manager IN ('Brian Norris', 'Wayne Coleman')
      AND cc.cc_gmt_offset > 0
      AND inv.inv_quantity_on_hand > 1000
    GROUP BY s.s_store_id, s.s_store_name, s.s_manager
),
avg_profit AS (
    SELECT AVG(total_net_profit) AS avg_net_profit FROM sales_agg
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_manager,
    a.total_net_profit,
    a.total_sales_transactions,
    a.total_catalog_return_amount,
    a.total_store_return_loss,
    RANK() OVER (ORDER BY a.total_net_profit DESC) AS profit_rank,
    CASE WHEN a.total_net_profit > p.avg_net_profit THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category
FROM sales_agg a
CROSS JOIN avg_profit p
ORDER BY profit_rank
LIMIT 100
