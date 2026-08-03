WITH union_returns AS (
    SELECT
        wr.wr_returned_date_sk AS return_date_sk,
        cd.cd_gender,
        r.r_reason_desc,
        wr.wr_return_amt,
        wr.wr_account_credit,
        CASE WHEN wr.wr_return_amt > 100 THEN 'high' ELSE 'low' END AS amt_category
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cd.cd_dep_count >= 2
      AND r.r_reason_id = 'AAAAAAAAABAAAAAA'
    UNION ALL
    SELECT
        wr.wr_returned_date_sk AS return_date_sk,
        cd.cd_gender,
        r.r_reason_desc,
        wr.wr_return_amt,
        wr.wr_account_credit,
        CASE WHEN wr.wr_return_amt > 100 THEN 'high' ELSE 'low' END AS amt_category
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cd.cd_dep_employed_count = 0
      AND r.r_reason_desc LIKE '%size%'
)
SELECT
    ur.return_date_sk,
    COUNT(DISTINCT ur.cd_gender) AS distinct_gender_cnt,
    SUM(DISTINCT ur.wr_return_amt) AS sum_distinct_return_amt,
    AVG(ur.wr_account_credit) AS avg_account_credit,
    CASE
        WHEN SUM(ur.wr_return_amt) > (
            SELECT AVG(wr_return_amt)
            FROM web_returns
            WHERE wr_reason_sk = 14
        ) THEN 'above_avg'
        ELSE 'below_avg'
    END AS return_amt_category
FROM union_returns ur
GROUP BY ur.return_date_sk
ORDER BY ur.return_date_sk DESC
LIMIT 100
