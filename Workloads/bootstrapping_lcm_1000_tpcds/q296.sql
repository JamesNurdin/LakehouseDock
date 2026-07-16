SELECT
    d_cr.d_year AS return_year,
    d_cr.d_month_seq AS month_seq,
    s.s_state AS state,
    p_start.p_channel_email AS promo_email_channel,
    CASE WHEN p_start.p_discount_active = 'Y' THEN 'Discount' ELSE 'NoDiscount' END AS discount_flag,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_net_loss) AS catalog_total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    SUM(sr.sr_net_loss) AS store_total_net_loss,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(sr.sr_return_amt_inc_tax) AS store_return_amount_inc_tax,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    (SUM(sr.sr_net_loss) / NULLIF(SUM(cr.cr_net_loss), 0)) AS store_to_catalog_loss_ratio
FROM catalog_returns cr
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN promotion p_start ON p_start.p_start_date_sk = d_cr.d_date_sk
JOIN promotion p_end ON p_end.p_end_date_sk = d_cr.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_cr.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sc ON s.s_closed_date_sk = d_sc.d_date_sk
WHERE p_start.p_discount_active = 'Y' OR p_end.p_discount_active = 'Y'
GROUP BY
    d_cr.d_year,
    d_cr.d_month_seq,
    s.s_state,
    p_start.p_channel_email,
    CASE WHEN p_start.p_discount_active = 'Y' THEN 'Discount' ELSE 'NoDiscount' END
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY d_cr.d_year, d_cr.d_month_seq
LIMIT 100
