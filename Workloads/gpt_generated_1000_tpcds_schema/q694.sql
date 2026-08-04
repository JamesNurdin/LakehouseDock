WITH sampled_returns AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE sr_reversed_charge > 100
),
joined_data AS (
    SELECT
        s.s_store_name,
        s.s_division_id,
        t.t_meal_time,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cs.cs_net_paid,
        sr.sr_return_amt
    FROM sampled_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = t.t_time_sk
       AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        t.t_meal_time = 'lunch'
        AND s.s_division_id = 1
        AND cd.cd_purchase_estimate >= 5000
),
aggregated AS (
    SELECT
        s_store_name,
        t_meal_time,
        cd_credit_rating,
        s_division_id,
        SUM(cs_net_paid) AS total_net_paid,
        AVG(sr_return_amt) AS avg_return_amt,
        CASE WHEN cd_credit_rating = 'Low Risk' THEN 'Preferred' ELSE 'Other' END AS customer_segment
    FROM joined_data
    GROUP BY
        s_store_name,
        t_meal_time,
        cd_credit_rating,
        s_division_id
)
SELECT
    s_store_name,
    t_meal_time,
    cd_credit_rating,
    total_net_paid,
    avg_return_amt,
    customer_segment,
    ROW_NUMBER() OVER (PARTITION BY s_division_id ORDER BY total_net_paid DESC) AS store_rank
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
