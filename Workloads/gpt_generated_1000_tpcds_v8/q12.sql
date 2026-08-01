WITH filtered AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_hdemo_sk,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        d.d_year,
        d.d_weekend,
        d.d_following_holiday,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_weekend = 'N'
      AND d.d_following_holiday = 'N'
      AND sr.sr_return_amt > 500
      AND hd.hd_vehicle_count <= 2
      AND d.d_year BETWEEN 2000 AND 2002
      AND sr.sr_return_quantity BETWEEN 1 AND 5
      AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_customer_sk = sr.sr_customer_sk
              AND sr2.sr_returned_date_sk < sr.sr_returned_date_sk
              AND sr2.sr_return_amt > 1000
        )
),
aggregated AS (
    SELECT
        COALESCE(CAST(d_year AS varchar), 'All Years') AS year,
        COALESCE(CAST(hd_income_band_sk AS varchar), 'All IncomeBands') AS income_band,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_customer_sk) AS distinct_customers,
        AVG(sr_return_quantity) AS avg_quantity
    FROM filtered
    GROUP BY GROUPING SETS (
        (d_year, hd_income_band_sk),
        (d_year),
        (hd_income_band_sk),
        ()
    )
),
ranked AS (
    SELECT
        year,
        income_band,
        total_return_amount,
        distinct_customers,
        avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_return_amount DESC) AS rn_year,
        RANK() OVER (PARTITION BY income_band ORDER BY distinct_customers DESC) AS rnk_income
    FROM aggregated
)
SELECT DISTINCT
    year,
    income_band,
    total_return_amount,
    distinct_customers,
    avg_quantity,
    rn_year,
    rnk_income
FROM ranked
WHERE rn_year <= 5
ORDER BY year, rn_year
LIMIT 100
