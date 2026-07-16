WITH total_loss AS (
    SELECT SUM(sr_net_loss) AS total_loss
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2452400 AND 2452600
),
customer_returns AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_quantity) AS total_quantity,
        MAX(sr.sr_returned_date_sk) AS last_return_date_sk
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2452400 AND 2452600
    GROUP BY sr.sr_customer_sk
),

demographic_snapshot AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year >= 1950
)
SELECT
    ds.c_customer_id,
    ds.c_first_name,
    ds.c_last_name,
    ds.c_birth_year,
    ds.cd_gender,
    ds.cd_education_status,
    ds.cd_credit_rating,
    ds.cd_marital_status,
    cr.total_net_loss,
    cr.avg_net_loss,
    cr.return_cnt,
    cr.total_quantity,
    (cr.total_net_loss / tl.total_loss) * 100.0 AS loss_percentage,
    RANK() OVER (ORDER BY cr.total_net_loss DESC) AS loss_rank,
    PERCENT_RANK() OVER (ORDER BY cr.total_net_loss DESC) AS loss_percent_rank
FROM demographic_snapshot ds
JOIN customer_returns cr
    ON ds.c_customer_sk = cr.sr_customer_sk
CROSS JOIN total_loss tl
WHERE cr.total_net_loss > 1000
ORDER BY cr.total_net_loss DESC
LIMIT 10
