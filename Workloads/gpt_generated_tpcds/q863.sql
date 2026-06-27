WITH combined_returns AS (
    SELECT cr.cr_returned_date_sk AS returned_date_sk,
           cr.cr_net_loss          AS net_loss,
           'catalog'               AS return_type
    FROM catalog_returns cr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_net_loss,
           'web'
    FROM web_returns wr
)
SELECT d.d_year,
       d.d_moy,
       cr.return_type,
       SUM(cr.net_loss) AS total_net_loss,
       COUNT(*)         AS return_count
FROM combined_returns cr
JOIN date_dim d ON cr.returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_moy, cr.return_type
ORDER BY d.d_year, d.d_moy, cr.return_type
