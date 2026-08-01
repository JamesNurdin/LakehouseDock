WITH unified_store_returns AS (
    SELECT
        sr.sr_returned_date_sk AS return_date_sk,
        sr.sr_net_loss AS net_loss,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc AS reason_desc,
        'store' AS channel
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
), unified_web_returns AS (
    SELECT
        wr.wr_returned_date_sk AS return_date_sk,
        wr.wr_net_loss AS net_loss,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc AS reason_desc,
        'web' AS channel
    FROM web_returns wr
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
), combined_returns AS (
    SELECT
        return_date_sk,
        net_loss,
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        reason_desc,
        channel
    FROM unified_store_returns
    UNION ALL
    SELECT
        return_date_sk,
        net_loss,
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        reason_desc,
        channel
    FROM unified_web_returns
)
SELECT
    channel,
    ib_lower_bound,
    ib_upper_bound,
    reason_desc,
    COUNT(*) AS return_count,
    SUM(net_loss) AS total_net_loss,
    CASE
        WHEN SUM(net_loss) > 1000 THEN 'High Loss'
        WHEN SUM(net_loss) > 0 THEN 'Medium Loss'
        ELSE 'Low/No Loss'
    END AS loss_category
FROM combined_returns
GROUP BY channel, ib_lower_bound, ib_upper_bound, reason_desc
ORDER BY total_net_loss DESC
