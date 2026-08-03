WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ca.ca_city,
        ca.ca_location_type,
        sm.sm_type,
        r.r_reason_desc,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        sr.sr_return_amt,
        ws.ws_ext_discount_amt,
        ws.ws_ext_ship_cost,
        ws.ws_net_paid,
        ws.ws_net_profit,
        wp.wp_web_page_id
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        cr.cr_return_amount > 100
        AND ws.ws_ext_discount_amt > 500
        AND ws.ws_ext_ship_cost < 2000
        AND c.c_birth_year BETWEEN 1978 AND 1990
        AND ca.ca_location_type = 'apartment'
        AND r.r_reason_desc LIKE '%Damaged%'
        AND sm.sm_type = 'AIR'
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ca_city,
    sm_type,
    r_reason_desc,
    ws_net_paid,
    ws_net_profit,
    cr_return_amount,
    sr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY ws_net_paid DESC) AS row_num
FROM base
ORDER BY row_num
LIMIT 100
