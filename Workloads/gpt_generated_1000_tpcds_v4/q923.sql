WITH male_returns AS (
    SELECT
        s.s_store_name AS store_name,
        s.s_state AS state,
        cd.cd_gender AS gender,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
      AND s.s_state IN ('CA', 'TX', 'NY')
    GROUP BY s.s_store_name, s.s_state, cd.cd_gender
),
female_returns AS (
    SELECT
        s.s_store_name AS store_name,
        s.s_state AS state,
        cd.cd_gender AS gender,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'F'
      AND s.s_state IN ('CA', 'TX', 'NY')
    GROUP BY s.s_store_name, s.s_state, cd.cd_gender
),
combined AS (
    SELECT DISTINCT * FROM male_returns
    UNION ALL
    SELECT DISTINCT * FROM female_returns
)
SELECT
    store_name,
    state,
    gender,
    total_return_amt,
    RANK() OVER (PARTITION BY gender ORDER BY total_return_amt DESC) AS gender_store_rank
FROM combined
ORDER BY gender, gender_store_rank
LIMIT 100
