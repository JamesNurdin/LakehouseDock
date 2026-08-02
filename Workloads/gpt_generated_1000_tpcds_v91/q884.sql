WITH sales_a AS (
    SELECT
        cs.cs_order_number,
        cp.cp_department,
        cp.cp_type,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        sd.d_year AS d_year,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim sd
        ON cs.cs_sold_date_sk = sd.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim psd
        ON cp.cp_start_date_sk = psd.d_date_sk
    JOIN date_dim ped
        ON cp.cp_end_date_sk = ped.d_date_sk
    WHERE cp.cp_catalog_number = 14
      AND cp.cp_catalog_page_number >= 8
      AND hd.hd_income_band_sk = 19
      AND hd.hd_dep_count <= 2
      AND sd.d_year = 1998
      AND sd.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-03-31'
      AND psd.d_date <= DATE '1998-12-31'
      AND ped.d_date >= DATE '1998-01-01'
      AND EXISTS (
            SELECT 1
            FROM customer_address ca_ship
            WHERE ca_ship.ca_address_sk = cs.cs_ship_addr_sk
              AND ca_ship.ca_city = 'New York'
        )
),
sales_b AS (
    SELECT
        cs.cs_order_number,
        cp.cp_department,
        cp.cp_type,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        sd.d_year AS d_year,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim sd
        ON cs.cs_sold_date_sk = sd.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim psd
        ON cp.cp_start_date_sk = psd.d_date_sk
    JOIN date_dim ped
        ON cp.cp_end_date_sk = ped.d_date_sk
    WHERE cp.cp_catalog_number = 17
      AND cp.cp_catalog_page_number <= 20
      AND hd.hd_income_band_sk = 10
      AND hd.hd_vehicle_count >= 1
      AND sd.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
      AND psd.d_date <= DATE '1999-12-31'
      AND ped.d_date >= DATE '1999-01-01'
      AND EXISTS (
            SELECT 1
            FROM customer_address ca_ship
            WHERE ca_ship.ca_address_sk = cs.cs_ship_addr_sk
              AND ca_ship.ca_state = 'CA'
        )
),
combined_sales AS (
    SELECT cs_order_number,
           cp_department,
           cp_type,
           cs_ext_sales_price,
           cs_quantity,
           d_year,
           hd_income_band_sk,
           hd_dep_count,
           hd_vehicle_count,
           cs_bill_customer_sk
    FROM sales_a
    UNION ALL
    SELECT cs_order_number,
           cp_department,
           cp_type,
           cs_ext_sales_price,
           cs_quantity,
           d_year,
           hd_income_band_sk,
           hd_dep_count,
           hd_vehicle_count,
           cs_bill_customer_sk
    FROM sales_b
),
excluded_sales AS (
    SELECT
        cs.cs_order_number,
        cp.cp_department,
        cp.cp_type,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        sd.d_year AS d_year,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim sd
        ON cs.cs_ship_date_sk = sd.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count = -1
),
final_sales AS (
    SELECT cs_order_number,
           cp_department,
           cp_type,
           cs_ext_sales_price,
           cs_quantity,
           d_year,
           hd_income_band_sk,
           hd_dep_count,
           hd_vehicle_count,
           cs_bill_customer_sk
    FROM combined_sales
    EXCEPT
    SELECT cs_order_number,
           cp_department,
           cp_type,
           cs_ext_sales_price,
           cs_quantity,
           d_year,
           hd_income_band_sk,
           hd_dep_count,
           hd_vehicle_count,
           cs_bill_customer_sk
    FROM excluded_sales
)
SELECT
    cp_department,
    cp_type,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_ext_sales_price) AS avg_sales,
    COUNT(*) AS sales_transactions,
    COUNT(DISTINCT cs_bill_customer_sk) AS distinct_customers,
    MIN(d_year) AS first_year,
    MAX(d_year) AS last_year
FROM final_sales
GROUP BY cp_department, cp_type
ORDER BY total_sales DESC
LIMIT 100
