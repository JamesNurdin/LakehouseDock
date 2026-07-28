WITH
    avg_item AS (
        SELECT AVG(sr_return_amt_inc_tax) AS avg_amt
        FROM store_returns
        WHERE sr_item_sk = 271991
    ),
    sub1 AS (
        SELECT
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            SUM(sr.sr_return_amt_inc_tax) AS total_amount,
            COUNT(*) AS return_cnt,
            (SELECT avg_amt FROM avg_item) AS avg_item_return_amt
        FROM store_returns sr
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_purchase_estimate > 5000
        GROUP BY cd.cd_gender, cd.cd_marital_status
    ),
    sub2 AS (
        SELECT
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            SUM(sr.sr_refunded_cash) AS total_amount,
            COUNT(*) AS return_cnt,
            (SELECT avg_amt FROM avg_item) AS avg_item_return_amt
        FROM store_returns sr
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_marital_status = 'M'
        GROUP BY cd.cd_gender, cd.cd_marital_status
    )
SELECT
    gender,
    marital_status,
    total_amount,
    return_cnt,
    avg_item_return_amt,
    ROW_NUMBER() OVER (PARTITION BY gender ORDER BY total_amount DESC) AS gender_rank
FROM (
    SELECT * FROM sub1
    UNION ALL
    SELECT * FROM sub2
) u
ORDER BY gender, gender_rank
LIMIT 100
