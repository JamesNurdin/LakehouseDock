SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_store_id,
    s.s_store_name,
    r.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    SUM(sr.sr_net_loss) / NULLIF(SUM(wr.wr_net_loss), 0) AS store_to_web_loss_ratio,
    MIN(d_closed.d_date) AS store_closed_date
FROM date_dim d
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_reason_sk = r.r_reason_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_store_id,
    s.s_store_name,
    r.r_reason_desc
ORDER BY total_store_net_loss DESC
LIMIT 100
