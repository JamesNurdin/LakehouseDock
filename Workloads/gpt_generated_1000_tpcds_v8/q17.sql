WITH sales_data AS (
    SELECT
        d.d_year,
        sm.sm_type,
        CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
          WHERE hd.hd_demo_sk = cs.cs_bill_hdemo_sk
            AND ib.ib_lower_bound > 150000
      )
    GROUP BY d.d_year,
             sm.sm_type,
             CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END
),
returns_data AS (
    SELECT
        d.d_year,
        sm.sm_type,
        CASE WHEN cr.cr_return_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_category,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year,
             sm.sm_type,
             CASE WHEN cr.cr_return_quantity > 5 THEN 'Large' ELSE 'Small' END
)
SELECT
    year,
    ship_mode_type,
    qty_category,
    SUM(total_sales) AS total_sales,
    SUM(total_returns) AS total_returns,
    SUM(total_sales) - SUM(total_returns) AS net_amount
FROM (
    SELECT
        d_year AS year,
        sm_type AS ship_mode_type,
        qty_category,
        total_sales,
        CAST(NULL AS decimal(7,2)) AS total_returns
    FROM sales_data
    UNION ALL
    SELECT
        d_year AS year,
        sm_type AS ship_mode_type,
        qty_category,
        CAST(NULL AS decimal(7,2)) AS total_sales,
        total_returns
    FROM returns_data
) combined
GROUP BY CUBE (year, ship_mode_type, qty_category)
ORDER BY year, ship_mode_type, qty_category
LIMIT 100
