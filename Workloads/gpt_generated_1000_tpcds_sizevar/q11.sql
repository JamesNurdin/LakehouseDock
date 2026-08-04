WITH male_agg AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        'Male_HighDep' AS segment
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M' AND cd.cd_dep_count > 3
    GROUP BY cd.cd_gender
),
female_agg AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        'Female_LowDep' AS segment
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_dep_count <= 3
    GROUP BY cd.cd_gender
),
combined AS (
    SELECT gender, segment, total_return_amt, avg_return_tax, return_cnt FROM male_agg
    UNION ALL
    SELECT gender, segment, total_return_amt, avg_return_tax, return_cnt FROM female_agg
)
SELECT
    gender,
    segment,
    total_return_amt,
    avg_return_tax,
    return_cnt,
    ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS rn
FROM combined
ORDER BY gender, total_return_amt DESC
