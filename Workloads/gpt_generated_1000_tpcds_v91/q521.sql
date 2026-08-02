WITH high_returns AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        SUM(cr.cr_return_amt_inc_tax) AS sum_inc_tax,
        AVG(cr.cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amt_inc_tax > 1500.00
      AND cr.cr_fee BETWEEN 20.00 AND 80.00
      AND cr.cr_store_credit < 150.00
      AND cr.cr_return_quantity >= 1
      AND cr.cr_returned_date_sk IN (20010101, 20010102, 20010103)
      AND EXISTS (
          SELECT 1
          FROM reason r2
          WHERE r2.r_reason_sk = cr.cr_reason_sk
            AND r2.r_reason_desc LIKE '%product%'
      )
    GROUP BY r.r_reason_sk, r.r_reason_desc
),
low_returns AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        SUM(cr.cr_return_amt_inc_tax) AS sum_inc_tax,
        AVG(cr.cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amt_inc_tax BETWEEN 300.00 AND 800.00
      AND cr.cr_fee < 30.00
      AND cr.cr_store_credit BETWEEN 50.00 AND 100.00
      AND cr.cr_return_quantity = 2
      AND cr.cr_returned_date_sk IN (20010104, 20010105)
      AND r.r_reason_id = 'AAAAAAAADAAAAAAA'
    GROUP BY r.r_reason_sk, r.r_reason_desc
)
SELECT
    combined.r_reason_desc,
    combined.sum_inc_tax,
    combined.avg_fee,
    combined.return_cnt,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_reason_sk = combined.r_reason_sk
          AND cr_sub.cr_return_quantity >= 5
    ) AS qty_5plus_cnt
FROM (
    SELECT r_reason_sk, r_reason_desc, sum_inc_tax, avg_fee, return_cnt
    FROM high_returns
    UNION ALL
    SELECT r_reason_sk, r_reason_desc, sum_inc_tax, avg_fee, return_cnt
    FROM low_returns
) AS combined
ORDER BY combined.r_reason_desc ASC
