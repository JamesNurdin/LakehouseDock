SELECT
    wr_returned_date_sk,
    COUNT(DISTINCT wr_order_number) AS distinct_order_cnt,
    SUM(wr_return_amt) AS total_return_amt
FROM web_returns
WHERE wr_fee > 20.00
  AND wr_reversed_charge < 200.00
GROUP BY wr_returned_date_sk
ORDER BY total_return_amt DESC
LIMIT 100
