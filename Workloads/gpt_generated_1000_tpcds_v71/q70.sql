SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COUNT(DISTINCT ss.ss_ticket_number)                     AS store_txn_cnt,
    SUM(ss.ss_net_paid)                                      AS store_total_paid,
    SUM(ss2.ss_net_paid)                                     AS store_total_paid_dup,
    COUNT(DISTINCT ws.ws_order_number)                      AS web_txn_cnt,
    SUM(ws.ws_net_paid)                                      AS web_total_paid,
    SUM(cr_refunded.cr_return_amount)                       AS total_return_amount,
    SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit ELSE 0 END)   AS positive_store_profit,
    SUM(CASE WHEN ws.ws_net_profit < 0 THEN ws.ws_net_profit ELSE 0 END)   AS negative_web_profit,
    COUNT(DISTINCT cp.cp_catalog_page_id)                   AS catalog_pages_viewed,
    CASE
        WHEN SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 5000 THEN 'High Value'
        ELSE 'Regular'
    END                                                     AS customer_segment
FROM
    customer c
JOIN store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN store_sales ss2
    ON ss2.ss_customer_sk = c.c_customer_sk
JOIN catalog_returns cr_refunded
    ON cr_refunded.cr_refunded_customer_sk = c.c_customer_sk
JOIN catalog_returns cr_returning
    ON cr_returning.cr_returning_customer_sk = c.c_customer_sk
JOIN catalog_page cp
    ON cr_refunded.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_sales ws2
    ON ws2.ws_ship_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_page wp2
    ON wp2.wp_customer_sk = c.c_customer_sk
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name
HAVING
    SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 1000
ORDER BY
    customer_segment DESC,
    store_total_paid DESC
LIMIT 100
