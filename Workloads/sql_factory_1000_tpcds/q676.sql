WITH refunded AS (
    SELECT
        wr.wr_refunded_hdemo_sk AS hd_demo_sk,
        SUM(wr.wr_return_amt_inc_tax) AS refunded_amt,
        SUM(wr.wr_net_loss) AS refunded_net_loss,
        MAX(d.d_date) AS latest_refund_date
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY wr.wr_refunded_hdemo_sk
),
returning AS (
    SELECT
        wr.wr_returning_hdemo_sk AS hd_demo_sk,
        SUM(wr.wr_return_amt_inc_tax) AS returning_amt,
        SUM(wr.wr_net_loss) AS returning_net_loss,
        MAX(d.d_date) AS latest_return_date
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY wr.wr_returning_hdemo_sk
),
combined AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COALESCE(f.refunded_amt, 0) AS total_refunded_amt,
        COALESCE(r.returning_amt, 0) AS total_returning_amt,
        COALESCE(f.refunded_net_loss, 0) + COALESCE(r.returning_net_loss, 0) AS total_net_loss,
        GREATEST(COALESCE(f.latest_refund_date, DATE '1970-01-01'), COALESCE(r.latest_return_date, DATE '1970-01-01')) AS latest_return_date
    FROM household_demographics hd
    LEFT JOIN refunded f
        ON hd.hd_demo_sk = f.hd_demo_sk
    LEFT JOIN returning r
        ON hd.hd_demo_sk = r.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE COALESCE(f.refunded_amt, 0) > 0 OR COALESCE(r.returning_amt, 0) > 0
)
SELECT
    hd_demo_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_refunded_amt,
    total_returning_amt,
    total_net_loss,
    latest_return_date,
    DENSE_RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    ROW_NUMBER() OVER (PARTITION BY ib_lower_bound ORDER BY latest_return_date DESC) AS recent_return_per_income_band
FROM combined
ORDER BY total_net_loss DESC
LIMIT 100
