WITH combined_returns AS (
    SELECT r.r_reason_desc AS reason_desc,
           SUM(cr.cr_net_loss) AS net_loss_total
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 100
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_reason_sk = r.r_reason_sk
            AND wr.wr_return_amt > 200
      )
    GROUP BY r.r_reason_desc
    HAVING SUM(cr.cr_net_loss) > 500

    UNION ALL

    SELECT r.r_reason_desc AS reason_desc,
           SUM(sr.sr_net_loss) AS net_loss_total
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_quantity > 2
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_reason_sk = r.r_reason_sk
            AND wr.wr_return_amt > 200
      )
    GROUP BY r.r_reason_desc
    HAVING SUM(sr.sr_net_loss) > 300
)
SELECT reason_desc,
       SUM(net_loss_total) AS total_net_loss
FROM combined_returns
GROUP BY reason_desc
HAVING SUM(net_loss_total) > 1000
ORDER BY total_net_loss DESC
