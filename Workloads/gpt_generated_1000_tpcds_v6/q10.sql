WITH avg_return_by_gender AS (
    SELECT cd.cd_gender,
           avg(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    avg_r.avg_return_amount
FROM catalog_returns cr
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN avg_return_by_gender avg_r
    ON cd.cd_gender = avg_r.cd_gender
WHERE cr.cr_return_amount > 150
  AND cd.cd_marital_status = 'M'
GROUP BY cd.cd_gender, cd.cd_marital_status, avg_r.avg_return_amount

UNION ALL

SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    avg_r.avg_return_amount
FROM catalog_returns cr
JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN avg_return_by_gender avg_r
    ON cd.cd_gender = avg_r.cd_gender
WHERE cr.cr_return_amount <= 150
  AND cd.cd_marital_status = 'S'
GROUP BY cd.cd_gender, cd.cd_marital_status, avg_r.avg_return_amount

ORDER BY total_return_amount DESC
LIMIT 100
