WITH sales_returns AS (
   SELECT
       d.d_year,
       ib.ib_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       ss.ss_ticket_number,
       ss.ss_net_paid,
       ss.ss_ext_sales_price,
       ss.ss_ext_discount_amt,
       ss.ss_quantity,
       cr.cr_return_amount,
       cr.cr_fee,
       cr.cr_store_credit,
       cr.cr_return_tax
   FROM catalog_returns cr
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store_sales ss
     ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
)
SELECT
    year,
    income_band_sk,
    orders,
    total_sales,
    total_returns,
    avg_discount,
    min_return_tax,
    max_income_upper
FROM (
   SELECT
       d_year AS year,
       ib_income_band_sk AS income_band_sk,
       COUNT(DISTINCT ss_ticket_number) AS orders,
       SUM(ss_net_paid) AS total_sales,
       SUM(cr_return_amount) AS total_returns,
       AVG(ss_ext_discount_amt) AS avg_discount,
       MIN(cr_return_tax) AS min_return_tax,
       MAX(ib_upper_bound) AS max_income_upper
   FROM sales_returns
   WHERE d_year = 2001
     AND ib_lower_bound >= 100000
     AND ss_quantity >= 2
     AND cr_fee > 30
     AND cr_store_credit < 100
     AND ss_ext_sales_price > 1000
   GROUP BY d_year, ib_income_band_sk
   UNION ALL
   SELECT
       d_year AS year,
       ib_income_band_sk AS income_band_sk,
       COUNT(DISTINCT ss_ticket_number) AS orders,
       SUM(ss_net_paid) AS total_sales,
       SUM(cr_return_amount) AS total_returns,
       AVG(ss_ext_discount_amt) AS avg_discount,
       MIN(cr_return_tax) AS min_return_tax,
       MAX(ib_upper_bound) AS max_income_upper
   FROM sales_returns
   WHERE d_year = 2002
     AND ib_upper_bound <= 150000
     AND ss_quantity >= 3
     AND cr_fee > 40
     AND cr_store_credit < 80
     AND ss_ext_sales_price > 2000
   GROUP BY d_year, ib_income_band_sk
) AS combined
ORDER BY year, income_band_sk
LIMIT 100
