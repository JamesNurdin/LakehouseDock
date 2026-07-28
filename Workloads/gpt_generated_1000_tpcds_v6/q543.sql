WITH reason_agg AS (
    SELECT
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HighLoss'
            ELSE 'LowLoss'
        END AS loss_category
    FROM tpcds.catalog_returns cr
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_fee > 20
        AND cr.cr_return_amount BETWEEN 10 AND 500
        AND r.r_reason_id IN ('AAAAAAAAFAAAAAAA', 'AAAAAAAACAAAAAAA')
        AND EXISTS (
            SELECT 1
            FROM tpcds.household_demographics hd
            WHERE hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
              AND hd.hd_dep_count >= 4
              AND hd.hd_buy_potential = '>10000'
        )
    GROUP BY r.r_reason_desc
)
SELECT
    ra.r_reason_desc,
    ra.total_return_amount,
    ra.total_fee,
    ra.return_cnt,
    ra.loss_category,
    ROW_NUMBER() OVER (ORDER BY ra.total_return_amount DESC) AS revenue_rank,
    AVG(ra.total_fee) OVER () AS avg_fee_all_reasons
FROM reason_agg ra
WHERE ra.return_cnt >= 5
ORDER BY ra.total_return_amount DESC
LIMIT 100
