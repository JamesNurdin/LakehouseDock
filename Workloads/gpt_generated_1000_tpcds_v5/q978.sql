WITH joined AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_dom,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
)
SELECT
    d_year,
    d_month_seq,
    CASE
        WHEN ib_upper_bound > 150000 THEN 'High'
        ELSE 'Low'
    END AS income_category,
    COUNT(*) AS total_returns,
    SUM(sr_return_amt) AS total_store_return_amt,
    SUM(wr_return_amt) AS total_web_return_amt,
    AVG(sr_return_amt + wr_return_amt) AS avg_combined_return_amt,
    MIN(sr_net_loss) AS min_store_net_loss,
    MAX(wr_net_loss) AS max_web_net_loss
FROM joined
WHERE
    d_year = 2001
    AND d_dom = 15
    AND ib_upper_bound <= 200000
    AND hd_vehicle_count >= 2
GROUP BY
    d_year,
    d_month_seq,
    CASE
        WHEN ib_upper_bound > 150000 THEN 'High'
        ELSE 'Low'
    END
ORDER BY
    d_year,
    d_month_seq,
    income_category
LIMIT 100
