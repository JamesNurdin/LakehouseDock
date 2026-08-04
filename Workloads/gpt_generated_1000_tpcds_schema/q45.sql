WITH
    ca_ss AS (
        SELECT * FROM customer_address
    ),
    ca_refund AS (
        SELECT * FROM customer_address
    ),
    ca_returning AS (
        SELECT * FROM customer_address
    ),
    ca_bill AS (
        SELECT * FROM customer_address
    ),
    ca_ship AS (
        SELECT * FROM customer_address
    ),
    td_ss AS (
        SELECT * FROM time_dim
    ),
    td_cr AS (
        SELECT * FROM time_dim
    ),
    td_ws AS (
        SELECT * FROM time_dim
    )
SELECT
    s.s_store_name,
    cp.cp_department,
    sm_cr.sm_type AS return_ship_type,
    sm_ws.sm_type AS web_ship_type,
    SUM(ss.ss_net_paid) AS sum_store_net_paid,
    SUM(ws.ws_net_paid_inc_ship) AS sum_web_net_paid,
    SUM(cr.cr_net_loss) AS sum_return_loss
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN td_ss
    ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
CROSS JOIN catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN td_cr
    ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
CROSS JOIN web_sales ws
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE s.s_gmt_offset > (
        SELECT AVG(s2.s_gmt_offset)
        FROM store s2
        WHERE s2.s_company_id = 1
    )
GROUP BY CUBE (
    s.s_store_name,
    cp.cp_department,
    sm_cr.sm_type,
    sm_ws.sm_type
)
ORDER BY sum_store_net_paid DESC, sum_web_net_paid DESC
LIMIT 100
