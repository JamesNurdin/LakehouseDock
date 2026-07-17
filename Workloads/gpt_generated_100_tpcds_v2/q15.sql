WITH cc_metrics AS (
    SELECT
        'call_center' AS category,
        CAST(AVG(cc_tax_percentage) AS DOUBLE) AS metric_value
    FROM call_center
    WHERE cc_tax_percentage > 0.05
      AND cc_state = 'CA'
),
cust_metrics AS (
    SELECT
        'customer' AS category,
        CAST(AVG(cd_purchase_estimate) AS DOUBLE) AS metric_value
    FROM customer_demographics
    WHERE cd_marital_status = 'M'
      AND cd_education_status = '4 yr Degree'
),
time_metrics AS (
    SELECT
        'time' AS category,
        CAST(COUNT(*) AS DOUBLE) AS metric_value
    FROM time_dim
    WHERE t_meal_time = 'Dinner'
      AND t_hour BETWEEN 18 AND 20
)
SELECT category, metric_value FROM cc_metrics
UNION ALL
SELECT category, metric_value FROM cust_metrics
UNION ALL
SELECT category, metric_value FROM time_metrics
ORDER BY category
