WITH
    store_agg AS (
        SELECT
            cust.c_customer_sk,
            cust.c_customer_id,
            cust.c_first_name,
            cust.c_last_name,
            cd.cd_purchase_estimate AS cd_purchase_estimate,
            SUM(ss.ss_net_paid) AS store_net_paid,
            SUM(ss.ss_net_profit) AS store_net_profit,
            COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
            SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss
        FROM store_sales ss
        JOIN time_dim td_store
            ON ss.ss_sold_time_sk = td_store.t_time_sk
        JOIN customer cust
            ON ss.ss_customer_sk = cust.c_customer_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN reason r_sr
            ON sr.sr_reason_sk = r_sr.r_reason_sk
        GROUP BY
            cust.c_customer_sk,
            cust.c_customer_id,
            cust.c_first_name,
            cust.c_last_name,
            cd.cd_purchase_estimate
    ),
    web_agg AS (
        SELECT
            cust_bill.c_customer_sk   AS cust_bill_sk,
            cust_bill.c_customer_id   AS cust_bill_id,
            cust_bill.c_first_name    AS cust_bill_first,
            cust_bill.c_last_name     AS cust_bill_last,
            cd_bill.cd_purchase_estimate AS cd_bill_purchase_est,
            cust_ship.c_customer_sk   AS cust_ship_sk,
            cd_ship.cd_purchase_estimate AS cd_ship_purchase_est,
            ws.ws_web_site_sk         AS web_site_sk,
            ws.ws_warehouse_sk        AS w_warehouse_sk,
            SUM(ws.ws_net_paid)       AS web_net_paid,
            SUM(ws.ws_net_profit)     AS web_net_profit,
            COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
            SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss
        FROM web_sales ws
        JOIN time_dim td_ws
            ON ws.ws_sold_time_sk = td_ws.t_time_sk
        JOIN customer cust_bill
            ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
        JOIN customer_demographics cd_bill
            ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer cust_ship
            ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
        JOIN customer_demographics cd_ship
            ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
        JOIN warehouse w
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_site site
            ON ws.ws_web_site_sk = site.web_site_sk
        LEFT JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
        LEFT JOIN reason r_wr
            ON wr.wr_reason_sk = r_wr.r_reason_sk
        LEFT JOIN time_dim td_ret
            ON wr.wr_returned_time_sk = td_ret.t_time_sk
        GROUP BY
            cust_bill.c_customer_sk,
            cust_bill.c_customer_id,
            cust_bill.c_first_name,
            cust_bill.c_last_name,
            cd_bill.cd_purchase_estimate,
            cust_ship.c_customer_sk,
            cd_ship.cd_purchase_estimate,
            ws.ws_web_site_sk,
            ws.ws_warehouse_sk
    )
SELECT
    DISTINCT cm.c_customer_id,
    cm.c_first_name,
    cm.c_last_name,
    cm.cd_purchase_estimate,
    cm.store_net_paid,
    cm.store_net_profit,
    cm.store_txn_cnt,
    cm.store_return_loss,
    wa.web_net_paid,
    wa.web_net_profit,
    wa.web_txn_cnt,
    wa.web_return_loss,
    wa.web_site_sk,
    wa.w_warehouse_sk,
    SUM(cm.store_net_paid + wa.web_net_paid) OVER (
        PARTITION BY cm.c_customer_id
        ORDER BY cm.store_net_paid DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_total_paid,
    ROW_NUMBER() OVER (ORDER BY (cm.store_net_paid + wa.web_net_paid) DESC) AS rank_by_total_paid
FROM store_agg cm
JOIN web_agg wa
    ON wa.cust_bill_id = cm.c_customer_id
ORDER BY rank_by_total_paid
LIMIT 100
