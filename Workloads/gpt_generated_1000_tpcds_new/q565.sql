WITH sr_data AS (
    SELECT
        d.d_date AS return_date,
        sr.sr_return_amt AS amount,
        sr.sr_net_loss AS net_loss,
        CASE WHEN sr.sr_return_amt > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
        r.r_reason_desc AS reason_desc
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    FULL OUTER JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_returned_date_sk = sr.sr_returned_date_sk
            AND cr.cr_reason_sk = sr.sr_reason_sk
            AND cr.cr_return_amount > 500
      )
),
cr_data AS (
    SELECT
        d.d_date AS return_date,
        cr.cr_return_amount AS amount,
        cr.cr_net_loss AS net_loss,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
        r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND hd.hd_dep_count >= 2
)
SELECT
    combined.return_date,
    combined.amount,
    combined.net_loss,
    combined.amount_category,
    combined.reason_desc
FROM (
    SELECT return_date, amount, net_loss, amount_category, reason_desc FROM sr_data
    UNION ALL
    SELECT return_date, amount, net_loss, amount_category, reason_desc FROM cr_data
) AS combined
ORDER BY combined.return_date DESC
LIMIT 100
