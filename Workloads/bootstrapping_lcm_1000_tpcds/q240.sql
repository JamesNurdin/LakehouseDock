SELECT
    s.s_division_name,
    d.d_year,
    d.d_quarter_name,
    ca_cr_refunded.ca_state AS refunded_state,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_return_quantity) AS catalog_return_quantity,
    SUM(wr.wr_return_quantity) AS web_return_quantity,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(cr.cr_fee) AS catalog_fee,
    SUM(wr.wr_fee) AS web_fee,
    COUNT(*) AS transaction_count
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer_address ca_cr_refunded
    ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
JOIN customer_address ca_cr_returning
    ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
JOIN customer_address ca_wr_refunded
    ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN customer_address ca_wr_returning
    ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
WHERE cr.cr_net_loss > 0
  AND wr.wr_net_loss > 0
GROUP BY ROLLUP(s.s_division_name, d.d_year, d.d_quarter_name, ca_cr_refunded.ca_state)
ORDER BY s.s_division_name, d.d_year, d.d_quarter_name, ca_cr_refunded.ca_state
LIMIT 100
