WITH filtered_join AS (
    SELECT
        cc.cc_state,
        r.r_reason_desc,
        cr.cr_return_amt_inc_tax,
        cr.cr_refunded_cash,
        cr.cr_return_quantity,
        rs.avg_return_by_reason
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT avg(cr2.cr_return_amt_inc_tax) AS avg_return_by_reason
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = r.r_reason_sk
    ) AS rs
    WHERE cc.cc_state = 'CA'
      AND cc.cc_sq_ft > 1000000
      AND cc.cc_zip LIKE '9%'
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND cr.cr_return_amt_inc_tax > 100
      AND cr.cr_refunded_cash <= 500
      AND cr.cr_return_quantity BETWEEN 1 AND 10
      AND r.r_reason_desc LIKE '%warranty%'
      AND cc.cc_country = 'United States'
),
aggregated AS (
    SELECT
        cc_state,
        r_reason_desc,
        SUM(cr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(cr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS num_returns,
        MIN(avg_return_by_reason) AS avg_return_by_reason
    FROM filtered_join
    GROUP BY ROLLUP (cc_state, r_reason_desc)
)
SELECT
    cc_state,
    r_reason_desc,
    total_return_inc_tax,
    total_refunded_cash,
    num_returns,
    avg_return_by_reason,
    DENSE_RANK() OVER (ORDER BY total_return_inc_tax DESC) AS return_amount_rank
FROM aggregated
ORDER BY return_amount_rank
LIMIT 100
