WITH catalog_agg AS (
  SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    sm.sm_type AS ship_type,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_discount_amt AS discount_amt,
    cs.cs_ext_sales_price AS sales_price
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2001
    AND cd.cd_gender = 'F'
    AND sm.sm_type = 'AIR'
),
store_agg AS (
  SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    'STORE' AS ship_type,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_discount_amt AS discount_amt,
    ss.ss_ext_sales_price AS sales_price
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2001
    AND cd.cd_gender = 'F'
)
SELECT
  year,
  gender,
  ship_type,
  SUM(net_profit) AS total_net_profit,
  SUM(sales_price) AS total_sales,
  AVG(discount_amt) AS avg_discount,
  COUNT(*) AS transaction_count
FROM (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM store_agg
) combined
GROUP BY year, gender, ship_type
HAVING SUM(net_profit) > 10000
ORDER BY total_net_profit DESC
