WITH joined AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        cd_ref.cd_gender AS refunded_gender,
        cd_ref.cd_marital_status AS refunded_marital_status,
        cd_ref.cd_education_status AS refunded_education_status,
        cd_ret.cd_gender AS returning_gender,
        cd_ret.cd_marital_status AS returning_marital_status,
        cd_ret.cd_education_status AS returning_education_status,
        cr.cr_reason_sk
    FROM catalog_returns cr
    LEFT JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    LEFT JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
)
SELECT
    refunded_gender,
    refunded_marital_status,
    refunded_education_status,
    returning_gender,
    returning_marital_status,
    returning_education_status,
    cr_reason_sk,
    COUNT(*) AS num_returns,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_quantity) AS avg_return_quantity,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_fee) AS total_fee,
    SUM(cr_return_ship_cost) AS total_ship_cost
FROM joined
GROUP BY
    refunded_gender,
    refunded_marital_status,
    refunded_education_status,
    returning_gender,
    returning_marital_status,
    returning_education_status,
    cr_reason_sk
ORDER BY total_net_loss DESC
LIMIT 100
