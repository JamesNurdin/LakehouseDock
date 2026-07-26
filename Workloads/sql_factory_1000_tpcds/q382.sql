WITH hd_state_daily_loss AS (
    SELECT
        hd.hd_income_band_sk,
        ca.ca_state,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS daily_net_loss,
        COUNT(*) AS daily_return_cnt
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY hd.hd_income_band_sk, ca.ca_state, sr.sr_returned_date_sk
),
state_income_total AS (
    SELECT
        hd_income_band_sk,
        ca_state,
        SUM(daily_net_loss) AS total_net_loss
    FROM hd_state_daily_loss
    GROUP BY hd_income_band_sk, ca_state
),
state_income_rank AS (
    SELECT
        hd_income_band_sk,
        ca_state,
        total_net_loss,
        DENSE_RANK() OVER (ORDER BY total_net_loss DESC) AS state_income_rank
    FROM state_income_total
)
SELECT
    d.hd_income_band_sk,
    d.ca_state,
    d.sr_returned_date_sk,
    d.daily_net_loss,
    d.daily_return_cnt,
    LAG(d.daily_net_loss) OVER (PARTITION BY d.hd_income_band_sk, d.ca_state ORDER BY d.sr_returned_date_sk) AS prev_day_net_loss,
    AVG(d.daily_net_loss) OVER (PARTITION BY d.hd_income_band_sk, d.ca_state ORDER BY d.sr_returned_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3d,
    r.total_net_loss,
    r.state_income_rank,
    CASE
        WHEN d.daily_net_loss > 5000 THEN 'HighLoss'
        WHEN d.daily_net_loss > 2000 THEN 'MediumLoss'
        ELSE 'LowLoss'
    END AS loss_category
FROM hd_state_daily_loss d
JOIN state_income_rank r
    ON d.hd_income_band_sk = r.hd_income_band_sk
    AND d.ca_state = r.ca_state
ORDER BY d.ca_state, d.hd_income_band_sk, d.sr_returned_date_sk
