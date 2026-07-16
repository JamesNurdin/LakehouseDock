SELECT r.r_reason_desc,
       r.r_reason_sk,
       SUM(cr.cr_return_amount) AS total_catalog_return_amount,
       (SELECT sr2.sr_return_quantity
        FROM store_returns sr2
        WHERE sr2.sr_returned_date_sk = 2451493
        LIMIT 1) AS sample_store_return_quantity
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
WHERE cr.cr_returned_date_sk = 2451049
GROUP BY r.r_reason_desc, r.r_reason_sk
HAVING COUNT(*) > 2451072
