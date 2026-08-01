WITH base_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        reason_desc.reason_desc,
        CASE WHEN cr.cr_return_amount > 500 THEN 'High' ELSE 'Normal' END AS return_category,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(cr.cr_net_loss) AS sum_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        max_by_reason.max_return_amount_for_reason_date,
        ca_refund.ca_address_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT r.r_reason_desc
        FROM reason r
        WHERE r.r_reason_sk = cr.cr_reason_sk
    ) AS reason_desc(reason_desc)
    CROSS JOIN LATERAL (
        SELECT MAX(cr2.cr_return_amount) AS max_return_amount_for_reason_date
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = cr.cr_reason_sk
          AND cr2.cr_returned_date_sk = cr.cr_returned_date_sk
    ) AS max_by_reason
    WHERE
        d.d_year = 2000
        AND d.d_month_seq BETWEEN 1500 AND 1600
        AND t.t_hour >= 12
        AND ca_refund.ca_state = 'CA'
        AND hd_refund.hd_income_band_sk IN (13, 14)
        AND cr.cr_return_amount > 100
        AND hd_refund.hd_vehicle_count >= 2
        AND t.t_minute IN (13, 19)
        AND EXISTS (
            SELECT 1
            FROM reason r_exist
            WHERE r_exist.r_reason_sk = cr.cr_reason_sk
              AND r_exist.r_reason_desc LIKE '%damaged%'
        )
    GROUP BY
        d.d_year,
        d.d_month_seq,
        reason_desc.reason_desc,
        CASE WHEN cr.cr_return_amount > 500 THEN 'High' ELSE 'Normal' END,
        max_by_reason.max_return_amount_for_reason_date,
        ca_refund.ca_address_sk
    HAVING SUM(cr.cr_return_amount) > 200
),
avg_by_month AS (
    SELECT
        d_year,
        d_month_seq,
        AVG(sum_net_loss) AS avg_net_loss_month
    FROM base_agg
    GROUP BY d_year, d_month_seq
)
SELECT
    ba.d_year,
    ba.d_month_seq,
    ba.reason_desc,
    ba.return_category,
    ba.sum_return_amount,
    ba.sum_net_loss,
    ba.return_cnt,
    ba.avg_return_amount,
    ba.max_return_amount_for_reason_date,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr_addr
        WHERE cr_addr.cr_refunded_addr_sk = ba.ca_address_sk
    ) AS total_returns_at_address,
    avgm.avg_net_loss_month
FROM base_agg ba
JOIN avg_by_month avgm
    ON ba.d_year = avgm.d_year
   AND ba.d_month_seq = avgm.d_month_seq
WHERE ba.sum_net_loss > avgm.avg_net_loss_month
ORDER BY ba.sum_net_loss DESC, ba.d_year ASC, ba.d_month_seq ASC
LIMIT 100
