SELECT
    CONCAT(CAST(d_ret.d_year AS VARCHAR), '-', LPAD(CAST(d_ret.d_moy AS VARCHAR), 2, '0')) AS year_month,
    s.s_state AS store_state,
    w.web_state AS website_state,
    CASE
        WHEN hd_ref.hd_income_band_sk <= 5 THEN 'Low'
        WHEN hd_ref.hd_income_band_sk <= 10 THEN 'Medium'
        ELSE 'High'
    END AS refunded_income_band_category,
    CASE
        WHEN hd_ret.hd_income_band_sk <= 5 THEN 'Low'
        WHEN hd_ret.hd_income_band_sk <= 10 THEN 'Medium'
        ELSE 'High'
    END AS returning_income_band_category,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_fee) AS total_fee,
    CASE
        WHEN SUM(cr.cr_return_quantity) = 0 THEN NULL
        ELSE SUM(cr.cr_return_amount) / SUM(cr.cr_return_quantity)
    END AS avg_amount_per_quantity
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site w
    ON w.web_open_date_sk = d_ret.d_date_sk
    AND w.web_close_date_sk = d_ret.d_date_sk
GROUP BY
    CONCAT(CAST(d_ret.d_year AS VARCHAR), '-', LPAD(CAST(d_ret.d_moy AS VARCHAR), 2, '0')),
    s.s_state,
    w.web_state,
    CASE
        WHEN hd_ref.hd_income_band_sk <= 5 THEN 'Low'
        WHEN hd_ref.hd_income_band_sk <= 10 THEN 'Medium'
        ELSE 'High'
    END,
    CASE
        WHEN hd_ret.hd_income_band_sk <= 5 THEN 'Low'
        WHEN hd_ret.hd_income_band_sk <= 10 THEN 'Medium'
        ELSE 'High'
    END
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
