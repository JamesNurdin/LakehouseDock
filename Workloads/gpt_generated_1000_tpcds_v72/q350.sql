WITH filtered_returns AS (
    SELECT DISTINCT
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 100.00
      AND cd.cd_purchase_estimate BETWEEN 3000 AND 9000
      AND ib.ib_upper_bound <= 60000
),
aggregated AS (
    SELECT
        fr.r_reason_desc,
        fr.ib_lower_bound,
        fr.ib_upper_bound,
        fr.cd_gender,
        SUM(fr.cr_return_amount) AS total_return_amount,
        AVG(fr.cr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
        MIN(fr.cr_return_amount) AS min_return,
        MAX(fr.cr_return_amount) AS max_return
    FROM filtered_returns fr
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = fr.cr_reason_sk
          AND cr2.cr_return_amount > 2000
    )
    GROUP BY fr.r_reason_desc, fr.ib_lower_bound, fr.ib_upper_bound, fr.cd_gender
)
SELECT
    r_reason_desc,
    ib_lower_bound,
    ib_upper_bound,
    cd_gender,
    total_return_amount,
    avg_return_qty,
    distinct_orders,
    min_return,
    max_return,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_rank,
    SUM(total_return_amount) OVER () AS grand_total
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
