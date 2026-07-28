WITH base AS (
    SELECT
        w.w_warehouse_name,
        r.r_reason_desc,
        c_refund.c_customer_id,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        td.t_hour
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    -- link to store sales via the same customer
    JOIN store_sales ss ON ss.ss_customer_sk = c_refund.c_customer_sk
    -- link to store returns via ticket number
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    -- link to web sales via the same customer (billing side)
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c_refund.c_customer_sk
    -- web page for the web sale
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    -- web returns linked to the web sale
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE r.r_reason_desc = 'Package was damaged'
      AND w.w_gmt_offset = -5.00
      AND td.t_hour BETWEEN 9 AND 17
      AND NOT EXISTS (
            SELECT 1 FROM store_returns sr2
            WHERE sr2.sr_reason_sk = r.r_reason_sk
              AND sr2.sr_net_loss > 1000
        )
)
SELECT
    w_warehouse_name,
    r_reason_desc,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(cr_net_loss) AS total_catalog_net_loss,
    SUM(sr_net_loss) AS total_store_net_loss,
    SUM(wr_net_loss) AS total_web_net_loss,
    AVG(ss_net_profit) AS avg_store_sales_profit,
    MAX(ws_net_profit) AS max_web_profit,
    MIN(t_hour) AS earliest_return_hour,
    (SELECT COUNT(*) FROM catalog_returns) AS total_catalog_returns
FROM base
GROUP BY w_warehouse_name, r_reason_desc
ORDER BY total_catalog_net_loss DESC
LIMIT 100
