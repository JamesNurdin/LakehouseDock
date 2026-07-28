WITH agg_a AS (
    SELECT
        t.t_shift,
        cd.cd_gender,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_fee > 20
      AND cd.cd_dep_employed_count >= 1
    GROUP BY t.t_shift, cd.cd_gender
),
agg_b AS (
    SELECT
        t.t_shift,
        cd.cd_gender,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_fee <= 20
      AND cd.cd_marital_status = 'S'
    GROUP BY t.t_shift, cd.cd_gender
),
combined AS (
    SELECT * FROM agg_a
    UNION ALL
    SELECT * FROM agg_b
)
SELECT
    t_shift,
    cd_gender,
    total_return_amt,
    return_cnt,
    RANK() OVER (PARTITION BY cd_gender ORDER BY total_return_amt DESC) AS gender_rank
FROM combined
ORDER BY total_return_amt DESC
LIMIT 100
