WITH dept_profit_preferred AS (
  SELECT cp.cp_department AS department,
         SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cp.cp_start_date_sk BETWEEN 2450900 AND 2451100
    AND c.c_preferred_cust_flag = 'Y'
    AND cd.cd_gender = 'M'
  GROUP BY cp.cp_department
  HAVING SUM(cs.cs_net_profit) > 10000
),
dept_profit_nonpreferred AS (
  SELECT cp.cp_department AS department,
         SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
  WHERE cp.cp_end_date_sk BETWEEN 2451150 AND 2451200
    AND c.c_preferred_cust_flag = 'N'
    AND cd.cd_gender = 'F'
  GROUP BY cp.cp_department
  HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT DISTINCT department, total_profit
FROM (
  SELECT department, total_profit FROM dept_profit_preferred
  UNION ALL
  SELECT department, total_profit FROM dept_profit_nonpreferred
) combined
ORDER BY total_profit DESC
