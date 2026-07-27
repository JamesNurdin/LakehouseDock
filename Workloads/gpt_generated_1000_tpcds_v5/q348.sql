WITH high_credit AS (
    SELECT
        c.c_customer_id,
        cd.cd_credit_rating,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_net_loss) > 100 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_count >= 2
      AND sr.sr_return_tax > 5
      AND c.c_last_review_date >= 2452500
    GROUP BY c.c_customer_id, cd.cd_credit_rating
),
low_credit AS (
    SELECT
        c.c_customer_id,
        cd.cd_credit_rating,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_net_loss) > 100 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND cd.cd_dep_college_count = 0
      AND sr.sr_return_tax <= 5
      AND c.c_last_review_date < 2452600
    GROUP BY c.c_customer_id, cd.cd_credit_rating
)
SELECT *
FROM (
    SELECT * FROM high_credit
    UNION ALL
    SELECT * FROM low_credit
) AS combined
ORDER BY total_return_amt DESC
LIMIT 100
