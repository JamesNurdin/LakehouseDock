WITH store_returns_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        'Store' AS channel,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM store_returns sr
    INNER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    INNER JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'High Risk'
    GROUP BY r.r_reason_desc
),
web_returns_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        'Web' AS channel,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM web_returns wr
    INNER JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    INNER JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'High Risk'
    GROUP BY r.r_reason_desc
)
SELECT reason_desc, channel, total_return_amount, return_count
FROM store_returns_agg
UNION ALL
SELECT reason_desc, channel, total_return_amount, return_count
FROM web_returns_agg
ORDER BY reason_desc, channel
