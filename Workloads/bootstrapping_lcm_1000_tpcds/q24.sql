SELECT
    s.s_store_id,
    s.s_store_name,
    d_cr.d_year,
    d_cr.d_month_seq,
    r_cr.r_reason_desc AS catalog_return_reason,
    r_sr.r_reason_desc AS store_return_reason,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    (SUM(cr.cr_net_loss) - SUM(sr.sr_net_loss)) AS net_loss_diff,
    CASE
        WHEN SUM(sr.sr_net_loss) = 0 THEN NULL
        ELSE SUM(cr.cr_net_loss) / SUM(sr.sr_net_loss)
    END AS loss_ratio,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty
FROM store_returns sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sr.d_date_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_cr.d_year,
    d_cr.d_month_seq,
    r_cr.r_reason_desc,
    r_sr.r_reason_desc
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY net_loss_diff DESC
LIMIT 100
