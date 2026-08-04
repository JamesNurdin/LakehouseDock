WITH intersect_keys AS (
  SELECT ws_bill_customer_sk AS cust_sk FROM web_sales WHERE ws_ext_tax > 60
  INTERSECT
  SELECT ws_ship_customer_sk FROM web_sales WHERE ws_ext_tax > 60
),
agg AS (
  SELECT
    cd_b.cd_gender AS gender,
    cd_b.cd_marital_status AS marital_status,
    cd_b.cd_education_status AS education_status,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS cnt_sales
  FROM web_sales ws
  JOIN customer_demographics cd_b
    ON ws.ws_bill_cdemo_sk = cd_b.cd_demo_sk
  JOIN customer_demographics cd_s
    ON ws.ws_ship_cdemo_sk = cd_s.cd_demo_sk
  WHERE ws.ws_ext_tax > 15
    AND ws.ws_list_price BETWEEN 20 AND 200
    AND cd_b.cd_dep_count <= 3
    AND cd_b.cd_marital_status IN ('M', 'S')
    AND cd_s.cd_education_status = 'College'
    AND ws.ws_bill_customer_sk IN (SELECT cust_sk FROM intersect_keys)
  GROUP BY GROUPING SETS (
    (cd_b.cd_gender, cd_b.cd_marital_status, cd_b.cd_education_status),
    (cd_b.cd_gender, cd_b.cd_marital_status),
    (cd_b.cd_gender),
    ()
  )
)
SELECT
  gender,
  marital_status,
  education_status,
  total_sales,
  total_profit,
  cnt_sales,
  RANK() OVER (PARTITION BY gender ORDER BY total_sales DESC) AS sales_rank,
  CASE
    WHEN total_profit > 1000 THEN 'HIGH'
    WHEN total_profit > 0 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category
FROM agg
ORDER BY sales_rank, total_sales DESC
LIMIT 100
