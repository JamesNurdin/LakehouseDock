SELECT
    d.d_year,
    d.d_current_month,
    refunded_addr.ca_state AS refunded_state,
    returning_addr.ca_state AS returning_state,
    COUNT(DISTINCT cr.cr_order_number) AS orders_returned,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT s.s_store_id) AS stores_closed_on_date,
    MIN(s.s_gmt_offset) AS min_store_gmt_offset,
    MAX(s.s_gmt_offset) AS max_store_gmt_offset
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address refunded_addr
    ON cr.cr_refunded_addr_sk = refunded_addr.ca_address_sk
JOIN customer_address returning_addr
    ON cr.cr_returning_addr_sk = returning_addr.ca_address_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND cr.cr_net_loss > 0
GROUP BY
    d.d_year,
    d.d_current_month,
    refunded_addr.ca_state,
    returning_addr.ca_state
ORDER BY total_net_loss DESC
LIMIT 100
