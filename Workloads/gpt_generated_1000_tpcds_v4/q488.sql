SELECT
    cc.cc_name AS call_center_name,
    r.r_reason_desc AS return_reason,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    AVG(sr.sr_store_credit) AS avg_store_credit,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    (SELECT AVG(ss2.ss_net_profit) FROM tpcds.store_sales ss2) AS overall_avg_store_profit
FROM tpcds.store_sales ss
JOIN tpcds.customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN tpcds.customer_address ca_sr_addr
    ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
JOIN tpcds.customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.call_center cc_ret
    ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
JOIN tpcds.customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN tpcds.customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
GROUP BY
    cc.cc_name,
    r.r_reason_desc
ORDER BY total_store_profit DESC
LIMIT 100
