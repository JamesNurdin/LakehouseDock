WITH agg AS (
    SELECT
        cr.cr_ship_mode_sk,
        sm.sm_type,
        cr.cr_refunded_customer_sk,
        rc.c_salutation AS refunded_salutation,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer rc
        ON cr.cr_refunded_customer_sk = rc.c_customer_sk
    JOIN tpcds.customer rcn
        ON cr.cr_returning_customer_sk = rcn.c_customer_sk
    WHERE cr.cr_net_loss > 200
      AND cr.cr_return_quantity >= 1
      AND sm.sm_code = 'AIR'
      AND rc.c_salutation = 'Mr.'
      AND rcn.c_birth_day = 15
    GROUP BY cr.cr_ship_mode_sk, sm.sm_type, cr.cr_refunded_customer_sk, rc.c_salutation
    HAVING SUM(cr.cr_net_loss) > 500
)
SELECT
    agg.sm_type,
    agg.refunded_salutation,
    agg.total_net_loss,
    agg.return_cnt,
    agg.avg_return_amount,
    RANK() OVER (PARTITION BY agg.sm_type ORDER BY agg.total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY agg.sm_type, loss_rank
LIMIT 100
