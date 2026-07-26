WITH daily_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        AVG(ib.ib_lower_bound) AS avg_income_lower_bound,
        CASE
            WHEN SUM(wr.wr_return_amt_inc_tax) > 1000 THEN 'High'
            ELSE 'Low'
        END AS return_level
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq
)
SELECT
    d_date,
    d_year,
    d_month_seq,
    total_return_inc_tax,
    total_net_loss,
    distinct_orders,
    avg_income_lower_bound,
    return_level,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_inc_tax DESC) AS yearly_return_rank,
    DENSE_RANK() OVER (ORDER BY total_net_loss DESC) AS overall_net_loss_rank
FROM daily_agg
ORDER BY d_year, d_month_seq
