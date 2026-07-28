WITH base AS (
    SELECT
        cr.cr_order_number,
        cs.cs_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        cr.cr_net_loss,
        s.s_state,
        CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN tpcds.customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN tpcds.customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN tpcds.customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN tpcds.catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN tpcds.customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN tpcds.customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_customer_sk = c_bill.c_customer_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
)
SELECT
    region,
    s_state,
    COUNT(DISTINCT cr_order_number) AS order_cnt,
    SUM(cs_net_profit) AS total_catalog_profit,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(sr_net_loss) AS total_store_loss,
    SUM(cr_net_loss) AS total_catalog_return_loss
FROM base
GROUP BY region, s_state
ORDER BY total_catalog_profit DESC
LIMIT 100
