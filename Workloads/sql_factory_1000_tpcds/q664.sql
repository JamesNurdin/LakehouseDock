WITH sales_agg AS (
    SELECT
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_income_band_sk
),
returns_agg AS (
    SELECT
        hd.hd_income_band_sk,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT
    s.hd_income_band_sk,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) AS net_metric,
    CASE
        WHEN (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS net_metric_sign,
    RANK() OVER (ORDER BY (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) DESC) AS income_band_rank
FROM sales_agg s
LEFT JOIN returns_agg r ON s.hd_income_band_sk = r.hd_income_band_sk
ORDER BY income_band_rank
