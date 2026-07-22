WITH base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_addr_sk,
        cr.cr_returning_customer_sk,
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_return_time_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_customer_sk,
        sr.sr_addr_sk,
        cc.cc_state,
        cp.cp_department,
        r_cr.r_reason_desc AS catalog_reason_desc,
        r_sr.r_reason_desc AS store_reason_desc,
        w.w_state,
        ca_refunded.ca_city,
        td.t_hour,
        i.inv_quantity_on_hand,
        s.s_state,
        s.s_number_employees
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN customer_address ca_current ON c.c_current_addr_sk = ca_current.ca_address_sk
    JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
)
SELECT
    cc_state,
    s_state,
    catalog_reason_desc,
    store_reason_desc,
    COUNT(DISTINCT cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT sr_ticket_number) AS store_return_tickets,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    AVG(cr_net_loss) AS avg_catalog_net_loss,
    AVG(sr_net_loss) AS avg_store_net_loss,
    CASE
        WHEN SUM(cr_return_amount) > SUM(sr_return_amt) THEN 'Catalog Higher'
        ELSE 'Store Higher'
    END AS higher_return_source
FROM base
WHERE
    cc_state = 'CA'
    AND cp_department = 'Electronics'
    AND catalog_reason_desc LIKE '%color%'
    AND w_state = 'TX'
    AND ca_city = 'San Francisco'
    AND t_hour BETWEEN 9 AND 17
    AND inv_quantity_on_hand > (SELECT AVG(inv_quantity_on_hand) FROM inventory)
    AND s_number_employees >= 200
GROUP BY
    cc_state,
    s_state,
    catalog_reason_desc,
    store_reason_desc
ORDER BY total_catalog_return_amount DESC
LIMIT 100
