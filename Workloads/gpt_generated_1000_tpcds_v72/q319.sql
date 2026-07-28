WITH store_ret AS (
    SELECT
        d.d_date AS return_date,
        c.c_customer_id AS customer_id,
        sr.sr_return_amt AS return_amount,
        r.r_reason_desc AS reason_desc,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY sr.sr_return_amt DESC) AS rn
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND sr.sr_return_amt IS NOT NULL
),
catalog_ret AS (
    SELECT
        d.d_date AS return_date,
        c.c_customer_id AS customer_id,
        cr.cr_return_amount AS return_amount,
        r.r_reason_desc AS reason_desc,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY cr.cr_return_amount DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND cr.cr_return_amount IS NOT NULL
)
SELECT *
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
) combined
ORDER BY return_date DESC, rn ASC
LIMIT 100
