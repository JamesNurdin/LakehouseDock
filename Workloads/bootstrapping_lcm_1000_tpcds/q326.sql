WITH aggregated_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        cd_refunded.cd_gender AS refunded_gender,
        cd_refunded.cd_marital_status AS refunded_marital_status,
        cd_refunded.cd_credit_rating AS refunded_credit_rating,
        cd_returning.cd_gender AS returning_gender,
        cd_returning.cd_marital_status AS returning_marital_status,
        cd_returning.cd_credit_rating AS returning_credit_rating,
        d_ret.d_year AS returned_year,
        d_ret.d_month_seq AS returned_month_seq,
        d_ret.d_date AS returned_date,
        d_closed.d_year AS store_closed_year,
        d_closed.d_month_seq AS store_closed_month_seq,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    CROSS JOIN store s
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_ret.d_year = 2000
      AND s.s_state = 'CA'
      AND cd_refunded.cd_credit_rating = 'A'
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    returned_year,
    refunded_gender,
    returning_gender,
    total_return_amount,
    avg_fee,
    total_net_loss,
    num_returns,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rank
FROM (
    SELECT
        s_store_id,
        s_store_name,
        s_city,
        returned_year,
        refunded_gender,
        returning_gender,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_fee) AS avg_fee,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS num_returns
    FROM aggregated_returns
    GROUP BY
        s_store_id,
        s_store_name,
        s_city,
        returned_year,
        refunded_gender,
        returning_gender
) agg
ORDER BY rank
LIMIT 100
