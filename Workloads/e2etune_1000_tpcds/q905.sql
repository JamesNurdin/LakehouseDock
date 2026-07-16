WITH aggregated_returns AS (
    SELECT
        t.t_hour,
        t.t_shift,
        cd_refunded.cd_gender AS refunded_gender,
        cd_returning.cd_gender AS returning_gender,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_fee) AS avg_fee
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451150
      AND cr.cr_fee > 50.00
      AND cd_refunded.cd_gender IS NOT NULL
    GROUP BY
        t.t_hour,
        t.t_shift,
        cd_refunded.cd_gender,
        cd_returning.cd_gender
),
ranked_returns AS (
    SELECT
        ar.*, 
        RANK() OVER (ORDER BY ar.total_net_loss DESC) AS net_loss_rank
    FROM aggregated_returns ar
    WHERE ar.total_net_loss > 100
)
SELECT *
FROM ranked_returns
WHERE net_loss_rank <= 10
ORDER BY net_loss_rank
