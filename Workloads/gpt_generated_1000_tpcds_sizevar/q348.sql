WITH filtered AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'High Risk'
      AND cd.cd_marital_status = 'M'
      AND sr.sr_return_amt > 100
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY sr_net_loss DESC) AS loss_rank
    FROM filtered
),
high_loss AS (
    SELECT sr_customer_sk FROM ranked WHERE sr_net_loss > 300
),
low_loss AS (
    SELECT sr_customer_sk FROM ranked WHERE sr_net_loss < 100
),
final_set AS (
    SELECT sr_customer_sk FROM high_loss
    EXCEPT
    SELECT sr_customer_sk FROM low_loss
)
SELECT
    r.sr_customer_sk,
    r.sr_item_sk,
    r.sr_return_amt,
    r.sr_net_loss,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_credit_rating,
    COUNT(DISTINCT r.cd_gender) OVER () AS distinct_gender_cnt,
    SUM(DISTINCT r.sr_return_amt) OVER () AS sum_distinct_return_amt,
    r.loss_rank
FROM ranked r
WHERE r.sr_customer_sk IN (SELECT sr_customer_sk FROM final_set)
ORDER BY r.sr_net_loss DESC, r.sr_customer_sk
LIMIT 100
