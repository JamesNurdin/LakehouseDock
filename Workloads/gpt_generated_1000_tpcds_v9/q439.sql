WITH joined_data AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_customer_sk,
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_hdemo_sk,
        t.t_hour,
        t.t_meal_time,
        t.t_second
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
    WHERE
        cr.cr_refunded_hdemo_sk IN (5112, 6492)
        AND sr.sr_hdemo_sk IN (6240, 5852)
        AND cr.cr_return_quantity > 1
        AND sr.sr_store_credit >= 10.0
        AND t.t_second IN (8, 13)
        AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = cr.cr_item_sk
              AND sr2.sr_returned_date_sk = cr.cr_returned_date_sk
        )
), unioned_agg AS (
    SELECT
        jd.t_hour,
        jd.t_meal_time,
        jd.cr_refunded_hdemo_sk,
        SUM(jd.cr_return_amount) AS total_cr_return_amount,
        AVG(jd.cr_return_quantity) AS avg_cr_return_quantity,
        SUM(jd.sr_return_amt) AS total_sr_return_amt,
        COUNT(DISTINCT jd.cr_refunded_customer_sk) AS distinct_refunded_customers,
        CASE WHEN SUM(jd.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        (SELECT MAX(cr3.cr_net_loss) FROM catalog_returns cr3) AS max_cr_net_loss_global
    FROM joined_data jd
    WHERE jd.t_hour >= 12
    GROUP BY jd.t_hour, jd.t_meal_time, jd.cr_refunded_hdemo_sk

    UNION DISTINCT

    SELECT
        jd.t_hour,
        jd.t_meal_time,
        jd.cr_refunded_hdemo_sk,
        SUM(jd.cr_return_amount) AS total_cr_return_amount,
        AVG(jd.cr_return_quantity) AS avg_cr_return_quantity,
        SUM(jd.sr_return_amt) AS total_sr_return_amt,
        COUNT(DISTINCT jd.cr_refunded_customer_sk) AS distinct_refunded_customers,
        CASE WHEN SUM(jd.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        (SELECT MAX(cr3.cr_net_loss) FROM catalog_returns cr3) AS max_cr_net_loss_global
    FROM joined_data jd
    WHERE jd.t_hour < 12
    GROUP BY jd.t_hour, jd.t_meal_time, jd.cr_refunded_hdemo_sk
)
SELECT
    ua.t_hour,
    ua.t_meal_time,
    ua.cr_refunded_hdemo_sk,
    ua.total_cr_return_amount,
    ua.avg_cr_return_quantity,
    ua.total_sr_return_amt,
    ua.distinct_refunded_customers,
    ua.loss_category,
    ua.max_cr_net_loss_global,
    SUM(ua.total_cr_return_amount) OVER (
        PARTITION BY ua.t_hour
        ORDER BY ua.t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amount_by_hour,
    RANK() OVER (ORDER BY ua.total_cr_return_amount DESC) AS return_amount_rank
FROM unioned_agg ua
ORDER BY ua.t_hour, ua.t_meal_time
LIMIT 100
