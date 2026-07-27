WITH combined AS (
    -- Catalog returns side
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_return_amount AS return_amount,
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_fee > 50.00
      AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'

    UNION ALL

    -- Store returns side
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_return_amt AS return_amount,
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        CASE WHEN sr.sr_return_amt > 1000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_fee > 30.00
      AND r.r_reason_desc LIKE '%purchase%'
)
SELECT
    c.date_sk,
    c.return_amount,
    c.reason_desc,
    c.gender,
    c.amount_category,
    (
        SELECT AVG(c2.return_amount)
        FROM combined c2
        WHERE c2.reason_desc = c.reason_desc
    ) AS avg_return_amount_for_reason
FROM combined c
WHERE EXISTS (
    SELECT 1
    FROM reason r_chk
    WHERE r_chk.r_reason_desc = c.reason_desc
      AND r_chk.r_reason_id = 'AAAAAAAAPAAAAAAA'
)
ORDER BY c.return_amount DESC
LIMIT 100
