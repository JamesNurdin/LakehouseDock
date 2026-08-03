WITH
  sales_pre AS (
    SELECT
      cs.cs_bill_customer_sk AS cs_bill_customer_sk,
      cs.cs_catalog_page_sk AS cs_catalog_page_sk,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_ext_tax > 20
      AND cs.cs_sold_time_sk BETWEEN 40000 AND 90000
    GROUP BY cs.cs_bill_customer_sk, cs.cs_catalog_page_sk
  ),

  customer_detail AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_salutation,
      c.c_birth_day,
      c.c_current_hdemo_sk
    FROM customer c
    WHERE c.c_salutation = 'Mr.'
      AND c.c_birth_day BETWEEN 1 AND 20
  ),

  joined AS (
    SELECT
      cd.c_customer_sk,
      cd.c_first_name,
      cd.c_last_name,
      cp.cp_department,
      cp.cp_catalog_page_number,
      sp.total_sales,
      sp.total_profit,
      sp.order_cnt,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      (
        SELECT SUM(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = cd.c_customer_sk
      ) AS customer_total_sales
    FROM sales_pre sp
    JOIN customer_detail cd ON sp.cs_bill_customer_sk = cd.c_customer_sk
    JOIN catalog_page cp ON sp.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cd.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_page_number IN (3, 5, 14)
      AND ib.ib_lower_bound >= 30000
  ),

  aggregated AS (
    SELECT
      c_customer_sk,
      c_first_name,
      c_last_name,
      cp_department,
      cp_catalog_page_number,
      ib_lower_bound,
      ib_upper_bound,
      customer_total_sales,
      SUM(total_sales) AS sum_total_sales,
      SUM(total_profit) AS sum_total_profit,
      SUM(order_cnt) AS sum_order_cnt
    FROM joined
    GROUP BY GROUPING SETS (
        (c_customer_sk, c_first_name, c_last_name, cp_department, cp_catalog_page_number, ib_lower_bound, ib_upper_bound, customer_total_sales),
        (cp_department, ib_lower_bound, ib_upper_bound)
    )
    HAVING SUM(total_sales) > 1000
  ),

  ranked AS (
    SELECT
      *,
      RANK() OVER (PARTITION BY cp_department ORDER BY sum_total_sales DESC) AS dept_sales_rank,
      SUM(sum_total_sales) OVER (
        PARTITION BY cp_department
        ORDER BY sum_total_sales
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS dept_running_sales
    FROM aggregated
  ),

  exclude AS (
    SELECT *
    FROM ranked
    WHERE sum_total_sales < 800
  )

SELECT *
FROM ranked
EXCEPT
SELECT *
FROM exclude
ORDER BY dept_sales_rank
LIMIT 100
