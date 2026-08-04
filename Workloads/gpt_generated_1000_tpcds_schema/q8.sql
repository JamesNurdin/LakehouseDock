-- goal: Compare total sales and total return amounts per year and ship mode for shipments handled by carrier 'AIRBORNE', showing only groups that exceed defined amount thresholds.
WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        sm.sm_ship_mode_id AS ship_mode,
        'sales' AS record_type,
        SUM(cs.cs_ext_sales_price) AS total_amount,
        COUNT(*) AS transaction_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year BETWEEN 1910 AND 1919
      AND sm.sm_carrier = 'AIRBORNE'
    GROUP BY d.d_year, sm.sm_ship_mode_id
    HAVING SUM(cs.cs_ext_sales_price) > 10000
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        sm.sm_ship_mode_id AS ship_mode,
        'returns' AS record_type,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS transaction_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year BETWEEN 1910 AND 1919
      AND sm.sm_carrier = 'AIRBORNE'
    GROUP BY d.d_year, sm.sm_ship_mode_id
    HAVING SUM(cr.cr_return_amount) > 5000
)
SELECT year,
       ship_mode,
       record_type,
       total_amount,
       transaction_count
FROM sales_agg
UNION ALL
SELECT year,
       ship_mode,
       record_type,
       total_amount,
       transaction_count
FROM returns_agg
ORDER BY year,
         ship_mode,
         record_type
LIMIT 100
