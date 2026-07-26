WITH all_returns AS (
    SELECT cr.cr_reason_sk AS reason_sk,
           cr.cr_return_quantity AS return_qty,
           cr.cr_return_amount AS return_amt,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT wr.wr_reason_sk AS reason_sk,
           wr.wr_return_quantity AS return_qty,
           wr.wr_return_amt AS return_amt,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
)
SELECT r.r_reason_desc,
       SUM(ar.return_qty) AS total_return_qty,
       SUM(ar.return_amt) AS total_return_amt,
       SUM(ar.net_loss) AS total_net_loss,
       CASE
           WHEN SUM(ar.net_loss) > 10000 THEN 'HIGH'
           WHEN SUM(ar.net_loss) > 5000 THEN 'MEDIUM'
           ELSE 'LOW'
       END AS loss_category,
       DENSE_RANK() OVER (ORDER BY SUM(ar.net_loss) DESC) AS loss_rank
FROM all_returns ar
JOIN reason r ON ar.reason_sk = r.r_reason_sk
GROUP BY r.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 5
