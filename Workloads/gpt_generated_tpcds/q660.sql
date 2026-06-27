WITH store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        r.r_reason_desc,
        hd.hd_income_band_sk,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        r.r_reason_desc,
        hd.hd_income_band_sk,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        r.r_reason_desc,
        hd.hd_income_band_sk,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
combined_returns AS (
    SELECT d_year, d_moy, r_reason_desc, hd_income_band_sk, net_loss, return_quantity FROM store_returns_agg
    UNION ALL
    SELECT d_year, d_moy, r_reason_desc, hd_income_band_sk, net_loss, return_quantity FROM catalog_returns_agg
    UNION ALL
    SELECT d_year, d_moy, r_reason_desc, hd_income_band_sk, net_loss, return_quantity FROM web_returns_agg
)
SELECT
    combined_returns.d_year AS year,
    combined_returns.d_moy AS month,
    combined_returns.r_reason_desc AS reason,
    combined_returns.hd_income_band_sk AS income_band,
    SUM(combined_returns.net_loss) AS total_net_loss,
    SUM(combined_returns.return_quantity) AS total_return_quantity,
    AVG(combined_returns.net_loss) AS avg_net_loss_per_return
FROM combined_returns
GROUP BY
    combined_returns.d_year,
    combined_returns.d_moy,
    combined_returns.r_reason_desc,
    combined_returns.hd_income_band_sk
ORDER BY total_net_loss DESC, year, month
