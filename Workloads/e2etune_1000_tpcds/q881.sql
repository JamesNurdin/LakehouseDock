SELECT
    sr.sr_returned_date_sk AS return_date_key,
    sr.sr_reason_sk AS reason_key,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_txn,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_txn,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    CASE WHEN SUM(wr.wr_return_amt) = 0 THEN NULL
         ELSE SUM(sr.sr_return_amt) / SUM(wr.wr_return_amt)
    END AS store_to_web_return_ratio,
    (SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt)) AS total_return_amount
FROM store_returns sr
JOIN web_returns wr
  ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
 AND sr.sr_reason_sk = wr.wr_reason_sk
WHERE sr.sr_return_amt > 100
  AND wr.wr_return_amt > 100
  AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
GROUP BY sr.sr_returned_date_sk, sr.sr_reason_sk
HAVING (SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt)) > 500
ORDER BY total_return_amount DESC
LIMIT 50
