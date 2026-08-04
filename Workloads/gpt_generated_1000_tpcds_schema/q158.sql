WITH filtered AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_reversed_charge,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_dep_employed_count,
        r.r_reason_desc
    FROM tpcds.store_returns AS sr
    JOIN tpcds.customer_demographics AS cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.reason AS r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 100
      AND sr.sr_return_quantity BETWEEN 1 AND 5
      AND sr.sr_reversed_charge < 50
      AND cd.cd_education_status IN ('Advanced Degree', 'College')
      AND cd.cd_dep_employed_count >= 1
      AND r.r_reason_desc LIKE '%color%'
)
SELECT
    f.cd_gender,
    f.cd_education_status,
    f.sr_item_sk,
    f.sr_return_amt,
    f.sr_return_quantity,
    f.r_reason_desc,
    CASE
        WHEN f.cd_gender = 'M' THEN 'Male'
        WHEN f.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_label,
    RANK() OVER (PARTITION BY f.cd_education_status ORDER BY f.sr_return_amt DESC) AS education_return_rank,
    SUM(f.sr_return_amt) OVER (
        PARTITION BY f.cd_education_status
        ORDER BY f.sr_return_amt DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amt
FROM filtered AS f
ORDER BY f.cd_education_status, education_return_rank
LIMIT 100
