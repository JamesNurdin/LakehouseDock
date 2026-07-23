SELECT
    wr.wr_order_number,
    wr.wr_return_amt,
    wr.wr_refunded_cash,
    r.r_reason_desc
FROM web_returns AS wr
JOIN reason AS r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc = 'Did not like the color'
  AND wr.wr_refunded_cash > 500
LIMIT 100
