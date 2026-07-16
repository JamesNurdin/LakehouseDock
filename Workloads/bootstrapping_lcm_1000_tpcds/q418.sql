SELECT
    d.d_year,
    d.d_month_seq,
    s.s_market_desc,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
   AND s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_month_seq, s.s_market_desc
ORDER BY total_net_loss DESC
LIMIT 100
