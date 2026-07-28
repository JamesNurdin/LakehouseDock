WITH joined AS (
    SELECT
        cc.cc_name AS cc_name,
        cc.cc_state AS cc_state,
        ca.ca_state AS ca_state,
        p.p_promo_name AS p_promo_name,
        p.p_discount_active AS p_discount_active,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_quantity AS ss_quantity,
        ss.ss_ticket_number AS ss_ticket_number,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_quantity AS ws_quantity,
        ws.ws_order_number AS ws_order_number,
        cr.cr_return_amount AS cr_return_amount
    FROM call_center cc
    JOIN catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_promo_sk = p.p_promo_sk
)
SELECT
    cc_name,
    p_promo_name,
    ca_state,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ss_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT ws_order_number) AS distinct_web_orders
FROM joined
WHERE
    cc_state = 'CA'
    AND ca_state = 'TX'
    AND p_discount_active = 'Y'
    AND ss_quantity > 2
    AND ws_quantity > 1
    AND cr_return_amount > 500
GROUP BY
    cc_name,
    p_promo_name,
    ca_state
HAVING
    SUM(ss_net_paid) > 10000
ORDER BY
    total_store_sales DESC,
    total_web_sales DESC
LIMIT 100
