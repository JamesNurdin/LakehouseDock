SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    i.i_category AS item_category,
    r.r_reason_desc AS reason_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    COUNT(sr.sr_ticket_number) AS return_ticket_count,
    CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_create
    ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer_address ca_cust
    ON c.c_current_addr_sk = ca_cust.ca_address_sk
GROUP BY ROLLUP (d_ret.d_year, d_ret.d_month_seq, i.i_category, r.r_reason_desc)
ORDER BY return_year DESC, return_month_seq, total_net_loss DESC
LIMIT 100
