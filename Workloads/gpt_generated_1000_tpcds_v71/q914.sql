WITH sales_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        'SALES' AS metric_type,
        SUM(cs.cs_ext_sales_price) AS amount,
        SUM(SUM(cs.cs_ext_sales_price)) OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS running_amount,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'HIGH' ELSE 'NORMAL' END AS category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'AIRBORNE'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq
),
returns_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        'RETURNS' AS metric_type,
        SUM(cr.cr_return_amount) AS amount,
        SUM(SUM(cr.cr_return_amount)) OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS running_amount,
        CASE WHEN SUM(cr.cr_return_amount) > 20000 THEN 'HIGH' ELSE 'NORMAL' END AS category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE r.r_reason_desc LIKE '%damage%'
      AND sm.sm_carrier = 'AIRBORNE'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq
)
SELECT * FROM sales_monthly
UNION ALL
SELECT * FROM returns_monthly
ORDER BY year, month_seq, metric_type
LIMIT 100
