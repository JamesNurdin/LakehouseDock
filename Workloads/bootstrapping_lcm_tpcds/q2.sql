SELECT
    d.d_year,
    d.d_moy,
    s.s_state,
    s.s_city,
    COUNT(*) AS total_return_rows,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount,
    SUM(cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) AS total_combined_net_loss,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    CASE
        WHEN SUM(cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS loss_category
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 2020 AND 2022
GROUP BY d.d_year, d.d_moy, s.s_state, s.s_city
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY total_combined_net_loss DESC, d.d_year DESC, d.d_moy DESC
LIMIT 100
