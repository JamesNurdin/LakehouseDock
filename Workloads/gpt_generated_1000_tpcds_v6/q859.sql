/*
  Goal: Compare monthly total catalog sales to web return amounts for the year 2001, focusing on ship modes whose contract starts with 'P7FB' and households that own two or more vehicles. The query aggregates sales and returns per month, computes a net amount, and limits the result to the first 100 rows.
*/
WITH high_value_ship_modes AS (
    SELECT DISTINCT
        sm_ship_mode_sk,
        sm_ship_mode_id,
        sm_contract
    FROM ship_mode
    WHERE sm_contract LIKE 'P7FB%'
)
SELECT
    month_year,
    SUM(sales_amount)      AS total_sales,
    SUM(return_amount)     AS total_returns,
    SUM(sales_amount) - SUM(return_amount) AS net_amount
FROM (
    -- Catalog sales portion
    SELECT
        CAST(d.d_year AS VARCHAR) || '-' || LPAD(CAST(d.d_month_seq AS VARCHAR), 2, '0') AS month_year,
        cs.cs_ext_sales_price AS sales_amount,
        0.0                     AS return_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN high_value_ship_modes hsm ON cs.cs_ship_mode_sk = hsm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 5

    UNION ALL

    -- Web returns portion
    SELECT
        CAST(d.d_year AS VARCHAR) || '-' || LPAD(CAST(d.d_month_seq AS VARCHAR), 2, '0') AS month_year,
        0.0                     AS sales_amount,
        wr.wr_return_amt       AS return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = wr.wr_refunded_hdemo_sk
            AND hd.hd_vehicle_count >= 2
      )
) AS combined
GROUP BY month_year
ORDER BY month_year
LIMIT 100
