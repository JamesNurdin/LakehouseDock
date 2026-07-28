WITH catalog AS (
    SELECT cr.cr_returned_date_sk AS return_date_sk,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 30
    GROUP BY cr.cr_returned_date_sk
),
web AS (
    SELECT wr.wr_returned_date_sk AS return_date_sk,
           SUM(wr.wr_return_amt) AS total_return_amount,
           COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 30
    GROUP BY wr.wr_returned_date_sk
)
SELECT 'Catalog' AS source,
       return_date_sk,
       total_return_amount,
       return_cnt
FROM catalog
UNION ALL
SELECT 'Web' AS source,
       return_date_sk,
       total_return_amount,
       return_cnt
FROM web
ORDER BY source, return_date_sk DESC
LIMIT 100
