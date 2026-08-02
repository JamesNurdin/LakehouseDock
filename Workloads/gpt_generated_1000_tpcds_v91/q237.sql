SELECT
    d_cr.d_year AS return_year,
    i.i_category AS category,
    r_cr.r_reason_desc AS catalog_return_reason,
    r_sr.r_reason_desc AS store_return_reason,
    sm.sm_type AS ship_mode_type,
    p.p_promo_name AS promo_name,
    w.w_warehouse_name AS warehouse_name,
    wp.wp_type AS web_page_type,
    SUM(cr.cr_return_amount) AS total_catalog_return_amt,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty
FROM catalog_returns cr
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN date_dim d_wp_create ON d_wp_create.d_date_sk = d_cr.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE cr.cr_item_sk NOT IN (SELECT sr2.sr_item_sk FROM store_returns sr2)
GROUP BY
    d_cr.d_year,
    i.i_category,
    r_cr.r_reason_desc,
    r_sr.r_reason_desc,
    sm.sm_type,
    p.p_promo_name,
    w.w_warehouse_name,
    wp.wp_type
ORDER BY total_catalog_return_amt DESC
LIMIT 100
