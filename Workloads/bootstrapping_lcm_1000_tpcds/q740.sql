SELECT
    d.d_date,
    s.s_store_id,
    s.s_store_name,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_combined_net_loss,
    SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    SUM(cr.cr_return_quantity) + SUM(sr.sr_return_quantity) + SUM(wr.wr_return_quantity) AS total_return_qty,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amt,
    AVG(sr.sr_return_amt) AS avg_store_return_amt,
    AVG(wr.wr_return_amt) AS avg_web_return_amt,
    SUM(cr.cr_return_amount) + SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt) AS total_return_amount
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
WHERE d.d_year = 2002
GROUP BY d.d_date, s.s_store_id, s.s_store_name
ORDER BY total_return_amount DESC
LIMIT 100
