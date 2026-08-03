WITH filtered_cat AS (
    SELECT cr_reason_sk,
           cr_returned_date_sk,
           cr_return_amount,
           cr_return_tax,
           cr_net_loss
    FROM catalog_returns
    WHERE cr_return_amount > 1000
),
filtered_store AS (
    SELECT sr_reason_sk,
           sr_returned_date_sk,
           sr_return_amt,
           sr_return_tax,
           sr_net_loss
    FROM store_returns
    WHERE sr_return_amt > 500
),
cat_with_reason AS (
    SELECT fcr.*, r.r_reason_sk AS reason_sk
    FROM filtered_cat fcr
    JOIN reason r
      ON fcr.cr_reason_sk = r.r_reason_sk
),
store_with_reason AS (
    SELECT fsr.*, r.r_reason_sk AS reason_sk
    FROM filtered_store fsr
    JOIN reason r
      ON fsr.sr_reason_sk = r.r_reason_sk
),
joined AS (
    SELECT COALESCE(c.reason_sk, s.reason_sk) AS reason_sk,
           c.cr_returned_date_sk,
           s.sr_returned_date_sk,
           c.cr_return_amount,
           s.sr_return_amt,
           c.cr_net_loss,
           s.sr_net_loss
    FROM cat_with_reason c
    FULL OUTER JOIN store_with_reason s
      ON c.reason_sk = s.reason_sk
)
SELECT reason_sk,
       reason_desc,
       total_return_amount,
       max_tax,
       ranking
FROM (
    SELECT j.reason_sk,
           r.r_reason_desc AS reason_desc,
           (COALESCE(j.cr_return_amount, 0) + COALESCE(j.sr_return_amt, 0)) AS total_return_amount,
           (SELECT max(cr_return_tax)
            FROM catalog_returns cr2
            WHERE cr2.cr_reason_sk = j.reason_sk) AS max_tax,
           row_number() OVER (PARTITION BY j.reason_sk
                               ORDER BY (COALESCE(j.cr_return_amount, 0) + COALESCE(j.sr_return_amt, 0)) DESC) AS ranking
    FROM joined j
    JOIN reason r
      ON r.r_reason_sk = j.reason_sk
    WHERE j.cr_return_amount IS NOT NULL OR j.sr_return_amt IS NOT NULL
    UNION
    SELECT r.r_reason_sk AS reason_sk,
           r.r_reason_desc AS reason_desc,
           (SELECT sum(cr_return_amount)
            FROM catalog_returns cr
            WHERE cr.cr_reason_sk = r.r_reason_sk
              AND cr.cr_return_amount > 2000) AS total_return_amount,
           (SELECT max(cr_return_tax)
            FROM catalog_returns cr
            WHERE cr.cr_reason_sk = r.r_reason_sk) AS max_tax,
           1 AS ranking
    FROM reason r
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_reason_sk = r.r_reason_sk
          AND sr.sr_return_amt > 1500
    )
) final
WHERE ranking <= 5
ORDER BY total_return_amount DESC, reason_sk ASC
LIMIT 100
