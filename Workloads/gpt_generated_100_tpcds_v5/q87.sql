WITH filtered_customers AS (
    SELECT c.c_customer_sk,
           c.c_salutation,
           c.c_birth_year,
           c.c_current_hdemo_sk
    FROM tpcds.customer c
    WHERE c.c_salutation = 'Mr.'
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND c.c_first_sales_date_sk = 2451825
),
max_income_upper AS (
    SELECT MAX(ib_upper_bound) AS max_ub
    FROM tpcds.income_band
    WHERE ib_lower_bound > 50000
)
SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    fc.c_salutation,
    COUNT(DISTINCT fc.c_customer_sk) AS customer_cnt,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    MAX(ss.ss_net_profit) AS max_net_profit,
    (SELECT max_ub FROM max_income_upper) AS overall_max_income_upper
FROM filtered_customers fc
JOIN tpcds.store_sales ss
    ON ss.ss_customer_sk = fc.c_customer_sk
JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
   AND fc.c_current_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = fc.c_customer_sk
WHERE wp.wp_autogen_flag = 'N'
  AND ib.ib_lower_bound >= 50001
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_page wp2
        WHERE wp2.wp_customer_sk = fc.c_customer_sk
          AND wp2.wp_type = 'product'
          AND wp2.wp_rec_start_date >= DATE '2000-01-01'
    )
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, fc.c_salutation
ORDER BY total_sales DESC
LIMIT 100
