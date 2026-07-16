SELECT
    d.d_year,
    d.d_month_seq AS month,
    r.r_reason_desc,
    ca.ca_state AS customer_state,
    wp.wp_type AS page_type,
    cc.cc_division,
    COUNT(*) AS total_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_return_quantity) AS total_quantity,
    RANK() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY SUM(wr.wr_net_loss) DESC) AS loss_rank
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND wp.wp_type = 'product'
  AND ca.ca_state IN ('CA', 'NY', 'TX')
  AND cc.cc_division = 3
  AND cc.cc_gmt_offset = -5.00
GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc, ca.ca_state, wp.wp_type, cc.cc_division
ORDER BY d.d_year, month, loss_rank
