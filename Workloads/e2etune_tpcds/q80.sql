WITH sales_demo AS (
  SELECT
    cd_current.cd_gender AS cur_gender,
    cd_current.cd_marital_status AS cur_marital_status,
    cd_current.cd_education_status AS cur_education_status,
    cd_sale.cd_gender AS sale_gender,
    COUNT(*) AS sales_count,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(ss.ss_quantity) AS avg_quantity,
    SUM(CASE WHEN cd_current.cd_gender <> cd_sale.cd_gender THEN 1 ELSE 0 END) AS gender_change_cnt
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd_sale ON ss.ss_cdemo_sk = cd_sale.cd_demo_sk
  JOIN customer_demographics cd_current ON c.c_current_cdemo_sk = cd_current.cd_demo_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_year BETWEEN 1950 AND 1970
    AND c.c_birth_month = 6
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY cd_current.cd_gender, cd_current.cd_marital_status, cd_current.cd_education_status, cd_sale.cd_gender
  HAVING SUM(ss.ss_net_profit) > 5000
)
SELECT
  cur_gender,
  cur_marital_status,
  cur_education_status,
  sale_gender,
  sales_count,
  total_profit,
  total_sales,
  total_discount,
  avg_quantity,
  gender_change_cnt,
  (gender_change_cnt * 100.0 / sales_count) AS gender_change_pct,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM sales_demo
ORDER BY total_profit DESC
LIMIT 50
