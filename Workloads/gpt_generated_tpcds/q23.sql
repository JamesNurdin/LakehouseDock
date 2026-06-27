WITH combined_returns AS (
    SELECT
        cr_returned_date_sk AS return_date_sk,
        cr_refunded_hdemo_sk AS hd_demo_sk,
        cr_net_loss AS net_loss
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk AS return_date_sk,
        wr_refunded_hdemo_sk AS hd_demo_sk,
        wr_net_loss AS net_loss
    FROM web_returns
)
SELECT
    d.d_year,
    hd.hd_income_band_sk,
    SUM(cr.net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(cr.net_loss) AS avg_net_loss
FROM combined_returns cr
JOIN date_dim d
    ON cr.return_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON cr.hd_demo_sk = hd.hd_demo_sk
WHERE d.d_date >= DATE '2022-01-01'
  AND d.d_date <= DATE '2022-12-31'
GROUP BY d.d_year, hd.hd_income_band_sk
ORDER BY d.d_year, hd.hd_income_band_sk
