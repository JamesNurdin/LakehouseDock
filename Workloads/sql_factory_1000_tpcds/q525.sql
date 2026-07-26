WITH date_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(t.t_hour) AS avg_return_hour
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    GROUP BY d.d_date, d.d_year
),
ranked_dates AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY total_return_amount DESC) AS amount_rank,
        LAG(total_return_amount) OVER (ORDER BY total_return_amount DESC) AS previous_return_amount
    FROM date_agg
)
SELECT
    d_date,
    d_year,
    total_returns,
    total_return_amount,
    avg_return_tax,
    total_fee,
    total_net_loss,
    avg_return_hour,
    CASE
        WHEN total_net_loss > 5000 THEN 'HIGH_LOSS'
        WHEN total_net_loss > 2000 THEN 'MEDIUM_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category,
    amount_rank,
    previous_return_amount,
    total_return_amount - COALESCE(previous_return_amount, 0) AS amount_diff_from_prev
FROM ranked_dates
WHERE amount_rank <= 10
ORDER BY amount_rank
