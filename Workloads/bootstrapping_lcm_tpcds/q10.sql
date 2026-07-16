SELECT
    d.d_date,
    s.s_store_name,
    ca.ca_state,
    ca.ca_country,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amt_inc_tax,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amt_inc_tax,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    (SUM(sr.sr_return_amt) - SUM(wr.wr_return_amt)) AS net_return_difference
FROM customer_address ca
JOIN store_returns sr
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN web_returns wr
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    AND wr.wr_returning_addr_sk = ca.ca_address_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d
    ON d.d_date_sk = sr.sr_returned_date_sk
    AND d.d_date_sk = wr.wr_returned_date_sk
    AND d.d_date_sk = s.s_closed_date_sk
GROUP BY
    d.d_date,
    s.s_store_name,
    ca.ca_state,
    ca.ca_country
ORDER BY
    d.d_date DESC,
    total_store_return_amt DESC
LIMIT 100
