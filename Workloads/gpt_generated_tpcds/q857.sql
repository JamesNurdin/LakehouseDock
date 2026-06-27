WITH all_returns AS (
    -- Catalog returns joined to demographic and income band
    SELECT
        ib.ib_income_band_sk   AS ib_income_band_sk,
        ib.ib_lower_bound      AS ib_lower_bound,
        ib.ib_upper_bound      AS ib_upper_bound,
        'catalog'              AS return_channel,
        cr.cr_net_loss         AS net_loss,
        cr.cr_return_amount    AS return_amount
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Store returns joined to demographic and income band
    SELECT
        ib.ib_income_band_sk   AS ib_income_band_sk,
        ib.ib_lower_bound      AS ib_lower_bound,
        ib.ib_upper_bound      AS ib_upper_bound,
        'store'                AS return_channel,
        sr.sr_net_loss         AS net_loss,
        sr.sr_return_amt       AS return_amount
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    -- Web returns joined to demographic and income band
    SELECT
        ib.ib_income_band_sk   AS ib_income_band_sk,
        ib.ib_lower_bound      AS ib_lower_bound,
        ib.ib_upper_bound      AS ib_upper_bound,
        'web'                  AS return_channel,
        wr.wr_net_loss         AS net_loss,
        wr.wr_return_amt       AS return_amount
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    return_channel,
    COUNT(*)                         AS num_returns,
    SUM(return_amount)               AS total_return_amount,
    SUM(net_loss)                    AS total_net_loss,
    AVG(net_loss)                    AS avg_net_loss_per_return
FROM all_returns
GROUP BY
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    return_channel
ORDER BY
    ib_income_band_sk,
    return_channel
