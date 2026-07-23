WITH base AS (
    SELECT DISTINCT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_fee,
        cr.cr_store_credit,
        cr.cr_reason_sk,
        r.r_reason_id,
        r.r_reason_desc,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk,
        fd.cd_credit_rating      AS refunded_credit_rating,
        rd.cd_credit_rating      AS returning_credit_rating,
        fd.cd_dep_count          AS refunded_dep_count,
        rd.cd_dep_count          AS returning_dep_count
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_demographics fd
        ON cr.cr_refunded_cdemo_sk = fd.cd_demo_sk
    LEFT JOIN customer_demographics rd
        ON cr.cr_returning_cdemo_sk = rd.cd_demo_sk
    WHERE r.r_reason_id IN ('AAAAAAAAFAAAAAAA', 'AAAAAAAABBAAAAAA', 'AAAAAAAADAAAAAAA')
      AND cr.cr_net_loss > 0
      AND cr.cr_return_amount >= 10
),
agg AS (
    SELECT
        b.r_reason_desc,
        b.refunded_credit_rating,
        b.returning_credit_rating,
        SUM(b.cr_return_amount) AS total_return_amount,
        SUM(b.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT b.cr_order_number) AS distinct_orders,
        CASE
            WHEN SUM(b.cr_net_loss) > 10000 THEN 'High Loss'
            WHEN SUM(b.cr_net_loss) > 5000  THEN 'Medium Loss'
            ELSE 'Low Loss'
        END AS loss_category
    FROM base b
    GROUP BY
        b.r_reason_desc,
        b.refunded_credit_rating,
        b.returning_credit_rating
    HAVING COUNT(DISTINCT b.cr_order_number) >= 5
)
SELECT
    a.r_reason_desc,
    a.refunded_credit_rating,
    a.returning_credit_rating,
    a.total_return_amount,
    a.total_net_loss,
    a.distinct_orders,
    a.loss_category,
    RANK() OVER (PARTITION BY a.refunded_credit_rating ORDER BY a.total_net_loss DESC) AS loss_rank_by_refunded_credit,
    ROW_NUMBER() OVER (ORDER BY a.total_net_loss DESC) AS overall_loss_rank
FROM agg a
ORDER BY a.total_net_loss DESC
LIMIT 100
