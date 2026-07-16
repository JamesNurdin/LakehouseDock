SELECT
    d.d_year,
    d.d_month_seq,
    w.w_warehouse_name,
    s.s_market_desc,
    ws.web_name,
    CASE
        WHEN mod(d.d_month_seq, 2) = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END AS month_parity,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amt_inc_tax) AS avg_return_amount,
    MAX(cr.cr_return_amt_inc_tax) - MIN(cr.cr_return_amt_inc_tax) AS return_amount_range
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND w.w_state = 'CA'
  AND s.s_state = 'CA'
GROUP BY
    d.d_year,
    d.d_month_seq,
    w.w_warehouse_name,
    s.s_market_desc,
    ws.web_name,
    CASE
        WHEN mod(d.d_month_seq, 2) = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END
HAVING SUM(cr.cr_return_quantity) > 50
ORDER BY total_net_loss DESC
LIMIT 100
