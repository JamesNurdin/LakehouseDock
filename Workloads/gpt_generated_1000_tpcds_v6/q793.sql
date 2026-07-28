WITH sales_agg AS (
    SELECT
        d.d_year,
        ca.ca_state,
        hd.hd_income_band_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
        MIN(ss.ss_sales_price) AS min_price,
        MAX(ss.ss_sales_price) AS max_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1240
      AND c.c_birth_month = 5
      AND c.c_preferred_cust_flag = 'Y'
      AND hd.hd_income_band_sk = 5
      AND hd.hd_vehicle_count >= 2
      AND ca.ca_state = 'CA'
      AND ss.ss_ext_sales_price > 100
      AND ss.ss_quantity >= 2
    GROUP BY d.d_year, ca.ca_state, hd.hd_income_band_sk
)
SELECT
    d_year,
    ca_state,
    hd_income_band_sk,
    total_sales,
    avg_discount,
    order_cnt,
    min_price,
    max_price,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
