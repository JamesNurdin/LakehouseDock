WITH
  sales_a AS (
    SELECT
      cp.cp_department,
      cs.cs_bill_customer_sk,
      cs.cs_net_paid_inc_ship,
      cs.cs_coupon_amt,
      cs.cs_net_profit
    FROM catalog_sales cs
    RIGHT OUTER JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_net_paid_inc_ship > 2000
      AND cs.cs_coupon_amt < 300
      AND cp.cp_department = 'DEPARTMENT'
      AND cp.cp_start_date_sk BETWEEN 2450900 AND 2451400
      AND c.c_birth_country = 'USA'
  ),
  sales_b AS (
    SELECT
      cp.cp_department,
      cs.cs_bill_customer_sk,
      cs.cs_net_paid_inc_ship,
      cs.cs_coupon_amt,
      cs.cs_net_profit
    FROM catalog_sales cs
    RIGHT OUTER JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN customer c
      ON cs.cs_ship_customer_sk = c.c_customer_sk
    WHERE cs.cs_net_paid_inc_ship BETWEEN 1000 AND 1500
      AND cs.cs_coupon_amt BETWEEN 100 AND 400
      AND cp.cp_department = 'DEPARTMENT'
      AND cp.cp_start_date_sk BETWEEN 2450900 AND 2451400
      AND c.c_birth_country = 'USA'
  ),
  union_sales AS (
    SELECT * FROM sales_a
    UNION
    SELECT * FROM sales_b
  ),
  dept_agg AS (
    SELECT
      us.cp_department,
      COUNT(DISTINCT us.cs_bill_customer_sk) AS distinct_customers,
      SUM(us.cs_net_paid_inc_ship) AS total_net_paid,
      AVG(us.cs_net_profit) AS avg_profit,
      MIN(us.cs_net_profit) AS min_profit,
      MAX(us.cs_net_profit) AS max_profit,
      CASE
        WHEN SUM(us.cs_net_paid_inc_ship) > 20000 THEN 'High'
        ELSE 'Medium'
      END AS sales_category,
      (
        SELECT COUNT(DISTINCT cs2.cs_bill_customer_sk)
        FROM catalog_sales cs2
        JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
        WHERE cp2.cp_department = us.cp_department
      ) AS dept_customer_cnt
    FROM union_sales us
    GROUP BY us.cp_department
  )
SELECT
  d.cp_department,
  d.distinct_customers,
  d.total_net_paid,
  d.avg_profit,
  d.min_profit,
  d.max_profit,
  d.sales_category,
  d.dept_customer_cnt,
  ROW_NUMBER() OVER (PARTITION BY d.cp_department ORDER BY d.total_net_paid DESC) AS dept_rank
FROM dept_agg d
ORDER BY d.total_net_paid DESC
LIMIT 100
