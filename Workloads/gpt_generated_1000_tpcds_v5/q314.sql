WITH recent_dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    'store' AS return_channel,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(*) AS return_count
FROM store_returns sr
JOIN recent_dates rd ON sr.sr_returned_date_sk = rd.d_date_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
GROUP BY cd.cd_gender, cd.cd_marital_status

UNION ALL

SELECT
    'web' AS return_channel,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_count
FROM web_returns wr
JOIN recent_dates rd ON wr.wr_returned_date_sk = rd.d_date_sk
JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
GROUP BY cd.cd_gender, cd.cd_marital_status

ORDER BY total_return_amount DESC
LIMIT 100
