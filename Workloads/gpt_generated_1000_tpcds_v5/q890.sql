WITH sales AS (
    SELECT
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(cs.cs_ext_sales_price) AS metric_amount,
        COUNT(*) AS metric_count,
        'sales' AS activity_type
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND cs.cs_sales_price > 50
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(cs.cs_ext_sales_price) > 1000
),
returns AS (
    SELECT
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(wr.wr_return_amt) AS metric_amount,
        COUNT(*) AS metric_count,
        'returns' AS activity_type
    FROM web_returns wr
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wr.wr_return_amt > 20
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(wr.wr_return_amt) > 500
),
combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
)
SELECT
    income_lower,
    income_upper,
    activity_type,
    metric_amount,
    metric_count,
    ROW_NUMBER() OVER (PARTITION BY activity_type ORDER BY metric_amount DESC) AS rn,
    SUM(metric_amount) OVER (PARTITION BY activity_type ORDER BY metric_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_metric_amount
FROM combined
WHERE metric_amount > 2000
ORDER BY activity_type, metric_amount DESC
LIMIT 100
