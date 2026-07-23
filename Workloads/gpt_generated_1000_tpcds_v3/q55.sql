WITH
    max_store_loss AS (
        SELECT MAX(sr2.sr_net_loss) AS max_loss
        FROM store_returns sr2
        JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2000
    ),
    max_catalog_loss AS (
        SELECT MAX(cr2.cr_net_loss) AS max_loss
        FROM catalog_returns cr2
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2000
    )
SELECT
    'store' AS return_source,
    d.d_date AS return_date,
    r.r_reason_desc AS reason_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    (SELECT max_loss FROM max_store_loss) AS max_loss
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2000
  AND r.r_reason_desc LIKE '%purchase%'
GROUP BY d.d_date, r.r_reason_desc

UNION ALL

SELECT
    'catalog' AS return_source,
    d.d_date AS return_date,
    r.r_reason_desc AS reason_desc,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    (SELECT max_loss FROM max_catalog_loss) AS max_loss
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2000
  AND r.r_reason_desc LIKE '%purchase%'
GROUP BY d.d_date, r.r_reason_desc

ORDER BY total_net_loss DESC
LIMIT 100
