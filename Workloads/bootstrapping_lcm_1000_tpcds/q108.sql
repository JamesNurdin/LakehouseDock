SELECT
    s.s_store_name,
    s.s_state,
    d.d_year,
    ca_refund.ca_state AS refunded_state,
    ca_returning.ca_state AS returning_state,
    ca_sr.ca_state AS return_address_state,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_ticket_cnt,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amt,
    AVG(sr.sr_return_amt) AS avg_store_return_amt,
    (SUM(cr.cr_net_loss) - SUM(sr.sr_net_loss)) / NULLIF((SUM(cr.cr_return_quantity) + SUM(sr.sr_return_quantity)), 0) AS net_loss_per_item,
    CASE 
        WHEN SUM(cr.cr_net_loss) > SUM(sr.sr_net_loss) THEN 'CatalogHigher'
        WHEN SUM(cr.cr_net_loss) < SUM(sr.sr_net_loss) THEN 'StoreHigher'
        ELSE 'Equal'
    END AS net_loss_comparison
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
GROUP BY
    s.s_store_name,
    s.s_state,
    d.d_year,
    ca_refund.ca_state,
    ca_returning.ca_state,
    ca_sr.ca_state
HAVING
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) > 1000
ORDER BY
    net_loss_per_item DESC
LIMIT 100
