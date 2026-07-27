WITH base_customer AS (
    SELECT
        cust.c_customer_sk,
        cust.c_current_hdemo_sk,
        hd_cur.hd_buy_potential AS cust_buy_potential,
        hd_cur.hd_vehicle_count AS cust_vehicle_count
    FROM customer cust
    JOIN household_demographics hd_cur
        ON cust.c_current_hdemo_sk = hd_cur.hd_demo_sk
)
SELECT
    cc.cc_name AS call_center_name,
    base.cust_buy_potential AS customer_current_buy_potential,
    SUM(ss.ss_net_profit) AS total_store_sales_profit,
    SUM(ws.ws_net_profit) AS total_web_sales_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_transactions,
    CASE
        WHEN SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) - SUM(cr.cr_net_loss) > 0
        THEN 'POSITIVE'
        ELSE 'NEGATIVE'
    END AS overall_profit_indicator
FROM base_customer base
JOIN store_sales ss
    ON ss.ss_customer_sk = base.c_customer_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = base.c_customer_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = base.c_customer_sk
JOIN household_demographics hd_cr_ref
    ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = base.c_customer_sk
JOIN household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
GROUP BY
    cc.cc_name,
    base.cust_buy_potential
ORDER BY
    overall_profit_indicator DESC,
    cc.cc_name
