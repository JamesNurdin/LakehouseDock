WITH sales_data AS (
  SELECT
    cs.cs_net_profit AS net_profit,
    i.i_category,
    cd.cd_gender,
    cd.cd_education_status,
    i.i_item_id
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE regexp_like(i.i_item_desc, '(?i)coffee|tea')
    AND i.i_product_name LIKE '%Premium%'
  UNION ALL
  SELECT
    ss.ss_net_profit AS net_profit,
    i.i_category,
    cd.cd_gender,
    cd.cd_education_status,
    i.i_item_id
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE regexp_like(i.i_item_desc, '(?i)coffee|tea')
    AND i.i_product_name LIKE '%Premium%'
)
SELECT
  s.i_category,
  CONCAT(s.cd_gender, '_', s.cd_education_status) AS gender_education,
  SUM(s.net_profit) AS total_net_profit,
  COUNT(*) AS transaction_cnt,
  MIN(SUBSTRING(s.i_item_id, 1, 3)) AS item_id_prefix
FROM sales_data s
GROUP BY s.i_category, CONCAT(s.cd_gender, '_', s.cd_education_status)
ORDER BY total_net_profit DESC
LIMIT 100
