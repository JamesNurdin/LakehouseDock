WITH sampled_catalog AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),

catalog_filtered AS (
    SELECT
        'catalog' AS src,
        cr.cr_returned_date_sk AS return_date_sk,
        r.r_reason_desc AS reason_desc,
        cr.cr_return_amount AS return_amount,
        LAG(cr.cr_return_amount) OVER (PARTITION BY cr.cr_reason_sk ORDER BY cr.cr_returned_date_sk) AS lag_return_amount,
        (
            SELECT SUM(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_reason_sk = cr.cr_reason_sk
        ) AS reason_total_amount
    FROM sampled_catalog cr
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_order_number NOT IN (
          SELECT wr.wr_order_number
          FROM web_returns wr
          WHERE wr.wr_return_amt_inc_tax > 5000
      )
),

web_filtered AS (
    SELECT
        'web' AS src,
        wr.wr_returned_date_sk AS return_date_sk,
        r.r_reason_desc AS reason_desc,
        wr.wr_return_amt_inc_tax AS return_amount,
        LAG(wr.wr_return_amt_inc_tax) OVER (PARTITION BY wr.wr_reason_sk ORDER BY wr.wr_returned_date_sk) AS lag_return_amount,
        (
            SELECT SUM(wr2.wr_return_amt_inc_tax)
            FROM web_returns wr2
            WHERE wr2.wr_reason_sk = wr.wr_reason_sk
        ) AS reason_total_amount
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt_inc_tax BETWEEN 50 AND 5000
      AND wr.wr_order_number NOT IN (
          SELECT cr.cr_order_number
          FROM catalog_returns cr
          WHERE cr.cr_return_amount > 200
      )
)

SELECT src,
       return_date_sk,
       reason_desc,
       return_amount,
       lag_return_amount,
       reason_total_amount
FROM (
    SELECT src, return_date_sk, reason_desc, return_amount, lag_return_amount, reason_total_amount
    FROM catalog_filtered
    UNION
    SELECT src, return_date_sk, reason_desc, return_amount, lag_return_amount, reason_total_amount
    FROM web_filtered
) AS combined
ORDER BY return_amount DESC
LIMIT 100
