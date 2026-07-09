SELECT
  year,
  month_seq,
  reason_desc,
  state,
  total_return_amt,
  total_net_loss,
  avg_return_amt,
  distinct_page_types,
  net_loss_rank
FROM (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    r.r_reason_desc AS reason_desc,
    ca.ca_state AS state,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    COUNT(DISTINCT wp.wp_type) AS distinct_page_types,
    RANK() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY SUM(wr.wr_net_loss) DESC) AS net_loss_rank
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year = 2000
  GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc, ca.ca_state
) AS monthly_top_reasons
WHERE net_loss_rank <= 5
ORDER BY year, month_seq, net_loss_rank
