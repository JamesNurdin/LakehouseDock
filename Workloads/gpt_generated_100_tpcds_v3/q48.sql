WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        wr.wr_refunded_cash,
        wr.wr_reversed_charge,
        wr.wr_account_credit,
        wr.wr_net_loss,
        wr.wr_reason_sk,
        wr.wr_returning_customer_sk
    FROM web_returns wr
    WHERE wr.wr_fee > 20.00
      AND wr.wr_return_ship_cost BETWEEN 200.00 AND 800.00
      AND wr.wr_return_quantity >= 2
      AND wr.wr_returning_customer_sk IN (6914607, 10288429)
      AND wr.wr_return_amt > 100.00
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    SUM(fr.wr_return_amt) AS total_return_amount,
    AVG(fr.wr_fee) AS avg_fee,
    COUNT(*) AS return_count,
    MIN(fr.wr_return_ship_cost) AS min_ship_cost,
    MAX(fr.wr_return_ship_cost) AS max_ship_cost
FROM filtered_returns fr
JOIN reason r ON fr.wr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%damaged%'
  AND r.r_reason_id = 'AAAAAAAAGAAAAAAA'
GROUP BY r.r_reason_id, r.r_reason_desc
HAVING SUM(fr.wr_return_amt) > 5000
ORDER BY SUM(fr.wr_return_amt) DESC
LIMIT 100
