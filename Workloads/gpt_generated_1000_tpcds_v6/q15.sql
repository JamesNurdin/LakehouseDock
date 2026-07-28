WITH united AS (
    SELECT d.d_date AS return_date,
           r.r_reason_desc AS reason,
           SUM(sr.sr_net_loss) AS total_net_loss,
           'store' AS return_source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_net_loss > 0
    GROUP BY d.d_date, r.r_reason_desc

    UNION ALL

    SELECT d.d_date AS return_date,
           r.r_reason_desc AS reason,
           SUM(cr.cr_net_loss) AS total_net_loss,
           'catalog' AS return_source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_net_loss > 0
    GROUP BY d.d_date, r.r_reason_desc
)
SELECT u.return_date,
       u.reason,
       u.total_net_loss,
       u.return_source
FROM united u
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE d2.d_date = u.return_date
      AND r2.r_reason_desc = u.reason
)
ORDER BY u.return_date DESC, u.total_net_loss DESC
LIMIT 100
