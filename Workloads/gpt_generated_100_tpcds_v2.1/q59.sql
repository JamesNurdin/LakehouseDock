WITH joined_data AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        r.r_reason_desc,
        cd.cd_gender,
        sr.sr_ticket_number,
        sr.sr_net_loss,
        sr.sr_reversed_charge,
        cr.cr_order_number,
        cr.cr_net_loss,
        i.inv_quantity_on_hand
    FROM
        store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
            AND cr.cr_reason_sk = r.r_reason_sk
            AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
            AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT
    w_warehouse_id,
    w_city,
    r_reason_desc,
    cd_gender,
    COUNT(DISTINCT sr_ticket_number) AS store_return_cnt,
    SUM(sr_net_loss) AS store_net_loss,
    COUNT(DISTINCT cr_order_number) AS catalog_return_cnt,
    SUM(cr_net_loss) AS catalog_net_loss,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty,
    CASE
        WHEN SUM(sr_net_loss) > SUM(cr_net_loss) THEN 'Store'
        ELSE 'Catalog'
    END AS higher_loss_source
FROM
    joined_data
WHERE
    w_city = 'Fairview'
    AND inv_quantity_on_hand > 500
    AND sr_reversed_charge > 500
GROUP BY
    w_warehouse_id,
    w_city,
    r_reason_desc,
    cd_gender
ORDER BY
    store_net_loss DESC
LIMIT 100
