WITH returns_base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_refunded_hdemo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_returns cr
    INNER JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_return_amount > 50
      AND cr.cr_return_quantity >= 1
      AND hd.hd_dep_count <= 5
      AND hd.hd_buy_potential NOT IN ('Unknown')
      AND ib.ib_upper_bound > 50000
),
aggregated AS (
    SELECT
        rb.cr_reason_sk,
        (SELECT r.r_reason_desc FROM reason r WHERE r.r_reason_sk = rb.cr_reason_sk) AS reason_desc,
        rb.hd_buy_potential,
        rb.hd_dep_count,
        rb.hd_vehicle_count,
        rb.hd_income_band_sk,
        rb.ib_lower_bound,
        rb.ib_upper_bound,
        SUM(rb.cr_return_amount) AS total_return_amount,
        SUM(rb.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_events
    FROM returns_base rb
    WHERE EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = rb.cr_reason_sk
          AND r2.r_reason_desc LIKE '%Damaged%'
    )
    GROUP BY
        rb.cr_reason_sk,
        rb.hd_buy_potential,
        rb.hd_dep_count,
        rb.hd_vehicle_count,
        rb.hd_income_band_sk,
        rb.ib_lower_bound,
        rb.ib_upper_bound
    HAVING SUM(rb.cr_return_amount) > 1000
)
SELECT
    a.cr_reason_sk,
    a.reason_desc,
    a.hd_buy_potential,
    a.hd_dep_count,
    a.hd_vehicle_count,
    a.hd_income_band_sk,
    a.ib_lower_bound,
    a.ib_upper_bound,
    a.total_return_amount,
    a.total_net_loss,
    a.return_events,
    ROW_NUMBER() OVER (
        PARTITION BY a.hd_income_band_sk
        ORDER BY a.total_return_amount DESC
    ) AS rn_by_income_band,
    RANK() OVER (ORDER BY a.total_return_amount DESC) AS overall_return_rank
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 100
