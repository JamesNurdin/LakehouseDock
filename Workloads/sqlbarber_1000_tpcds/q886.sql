SELECT r.r_reason_desc,
       SUM(cr.cr_return_amount) AS total_catalog_return,
       COUNT(*) AS total_rows
FROM catalog_returns cr
INNER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
INNER JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
INNER JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
WHERE cr.cr_returned_date_sk = 2451109
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_returned_date_sk = 2451933
          AND sr2.sr_reason_sk = r.r_reason_sk
    )
GROUP BY r.r_reason_desc
HAVING r.r_reason_desc = 'Found a better extended warranty in a store                                                         '
