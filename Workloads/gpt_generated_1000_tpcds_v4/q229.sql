WITH joined AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cd.cd_gender,
        s.s_store_name,
        w.w_warehouse_name,
        r.r_reason_desc,
        ss.ss_net_profit,
        sr.sr_net_loss,
        cr.cr_net_loss,
        ws.ws_net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        ca.ca_gmt_offset BETWEEN -9.00 AND -6.00
        AND w.w_warehouse_sq_ft > 200000
        AND s.s_state = 'CA'
        AND cd.cd_gender = 'M'
        AND c.c_birth_year BETWEEN 1960 AND 1970
        AND r.r_reason_id LIKE 'AAAAAAA%'
        AND EXISTS (
            SELECT 1 FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_reason_sk = r.r_reason_sk
        )
),
 dedup AS (
    SELECT DISTINCT *
    FROM joined
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ca_state,
    cd_gender,
    s_store_name,
    w_warehouse_name,
    r_reason_desc,
    SUM(ss_net_profit)               AS total_store_profit,
    SUM(sr_net_loss)                 AS total_store_return_loss,
    SUM(cr_net_loss)                 AS total_catalog_return_loss,
    SUM(ws_net_profit)               AS total_web_profit,
    COUNT(*)                         AS txn_count
FROM dedup
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    ca_state,
    cd_gender,
    s_store_name,
    w_warehouse_name,
    r_reason_desc
HAVING
    SUM(ss_net_profit) > 1000
    AND SUM(sr_net_loss) < 500
    AND COUNT(*) >= 2
ORDER BY total_store_profit DESC
LIMIT 100
