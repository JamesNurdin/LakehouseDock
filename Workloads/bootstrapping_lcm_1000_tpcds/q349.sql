SELECT
    s.s_store_id,
    s.s_store_name,
    ca.ca_city,
    ca.ca_state,
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month_seq,
    d_closed.d_year AS closed_year,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    COUNT(*) AS total_returns,
    SUM(CASE WHEN wp.wp_type = 'product' THEN 1 ELSE 0 END) AS product_page_views,
    SUM(CASE WHEN wp.wp_type = 'landing' THEN 1 ELSE 0 END) AS landing_page_views,
    MAX(wp.wp_url) FILTER (WHERE wp.wp_type = 'landing') AS any_landing_url,
    SUM(CASE WHEN sr.sr_fee > 0 THEN sr.sr_fee ELSE 0 END) AS total_fees,
    SUM(CASE WHEN sr.sr_store_credit > 0 THEN sr.sr_store_credit ELSE 0 END) AS total_store_credit
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_return.d_date_sk
   AND wp.wp_access_date_sk = d_return.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    ca.ca_city,
    ca.ca_state,
    d_return.d_year,
    d_return.d_month_seq,
    d_closed.d_year
HAVING
    SUM(sr.sr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
