WITH joined AS (
    SELECT
        cr.cr_net_loss,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        d.d_year,
        d.d_quarter_name,
        r.r_reason_desc,
        hd_refunded.hd_income_band_sk AS refunded_income_band,
        hd_returning.hd_income_band_sk AS returning_income_band,
        s.s_store_name,
        s.s_city,
        s.s_state
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
),
aggregated AS (
    SELECT
        s_store_name,
        s_city,
        s_state,
        d_year,
        d_quarter_name,
        r_reason_desc,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr_return_amount) AS avg_return_amount,
        AVG(cr_return_quantity) AS avg_return_quantity,
        AVG(refunded_income_band) AS avg_refunded_income_band,
        AVG(returning_income_band) AS avg_returning_income_band
    FROM joined
    GROUP BY
        s_store_name,
        s_city,
        s_state,
        d_year,
        d_quarter_name,
        r_reason_desc
)
SELECT
    s_store_name,
    s_city,
    s_state,
    d_year,
    d_quarter_name,
    r_reason_desc,
    total_net_loss,
    return_cnt,
    avg_return_amount,
    avg_return_quantity,
    avg_refunded_income_band,
    avg_returning_income_band,
    RANK() OVER (PARTITION BY s_store_name ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
