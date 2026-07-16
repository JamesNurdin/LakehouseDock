WITH return_agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_ret.d_year,
        d_ret.d_quarter_name,
        d_ret.d_month_seq,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        hd_ret.hd_income_band_sk AS returning_income_band,
        wp.wp_type,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        DATE_DIFF('day', d_creation.d_date, d_ret.d_date) AS days_creation_to_return,
        CASE
            WHEN SUM(wr.wr_return_amt) > 10000 THEN 'HIGH'
            WHEN SUM(wr.wr_return_amt) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_amount_bucket
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    WHERE d_ret.d_year = 2022
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_ret.d_year,
        d_ret.d_quarter_name,
        d_ret.d_month_seq,
        hd_ref.hd_income_band_sk,
        hd_ret.hd_income_band_sk,
        wp.wp_type,
        d_creation.d_date,
        d_ret.d_date
)
SELECT
    ra.s_store_id,
    ra.s_city,
    ra.s_state,
    ra.d_year,
    ra.d_quarter_name,
    ra.d_month_seq,
    ra.refunded_income_band,
    ra.returning_income_band,
    ra.wp_type,
    ra.num_returns,
    ra.total_return_amt,
    ra.total_net_loss,
    ra.avg_return_qty,
    ra.days_creation_to_return,
    ra.return_amount_bucket,
    SUM(ra.total_return_amt) OVER (
        PARTITION BY ra.s_store_id
        ORDER BY ra.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amt_by_month,
    RANK() OVER (
        PARTITION BY ra.d_quarter_name
        ORDER BY ra.total_return_amt DESC
    ) AS store_quarter_rank
FROM return_agg ra
WHERE ra.num_returns > 5
ORDER BY ra.total_return_amt DESC
LIMIT 100
