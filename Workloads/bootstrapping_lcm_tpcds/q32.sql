SELECT
    c.c_birth_country,
    s.s_market_desc,
    ws.web_market_manager,
    EXTRACT(year FROM dr.d_date) AS return_year,
    EXTRACT(month FROM dr.d_date) AS return_month,
    EXTRACT(year FROM dcs.d_date) AS first_shipto_year,
    COUNT(*) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN sr.sr_fee > 0 THEN sr.sr_fee ELSE 0 END) AS total_fees,
    SUM(CASE WHEN sr.sr_store_credit > 0 THEN sr.sr_store_credit ELSE 0 END) AS total_store_credit,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    CASE WHEN SUM(sr.sr_return_amt) > 10000 THEN 'High' ELSE 'Low' END AS return_amount_category
FROM store_returns sr
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr
    ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN date_dim dw
    ON sr.sr_returned_date_sk = dw.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = dw.d_date_sk
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
JOIN date_dim dcs
    ON c.c_first_shipto_date_sk = dcs.d_date_sk
GROUP BY
    c.c_birth_country,
    s.s_market_desc,
    ws.web_market_manager,
    EXTRACT(year FROM dr.d_date),
    EXTRACT(month FROM dr.d_date),
    EXTRACT(year FROM dcs.d_date)
ORDER BY total_return_amount DESC
LIMIT 100
