WITH
  sales_agg AS (
    SELECT
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      hd.hd_buy_potential,
      SUM(ss.ss_ext_sales_price)          AS total_sales,
      AVG(ss.ss_net_paid_inc_tax)         AS avg_paid_inc_tax,
      COUNT(*)                            AS sales_cnt,
      ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS income_rank
    FROM store_sales ss
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    FULL OUTER JOIN household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_net_paid_inc_tax > 500
      AND ca.ca_location_type = 'single family'
      AND ib.ib_lower_bound >= 20000
      AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk
          AND ss2.ss_ext_discount_amt > 100
      )
    GROUP BY
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      hd.hd_buy_potential
  ),
  bucket AS (
    SELECT 1 AS bucket UNION ALL SELECT 2 UNION ALL SELECT 3
  )
SELECT
  sa.ib_income_band_sk,
  sa.ib_lower_bound,
  sa.ib_upper_bound,
  sa.hd_buy_potential,
  sa.total_sales,
  sa.avg_paid_inc_tax,
  sa.sales_cnt,
  sa.income_rank,
  b.bucket
FROM sales_agg sa
CROSS JOIN bucket b
WHERE b.bucket = 1
LIMIT 100
