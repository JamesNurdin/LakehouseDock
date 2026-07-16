WITH sales_agg AS (
  SELECT
    cp.cp_type,
    i.i_category,
    i.i_brand,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
    AND cp.cp_type IN ('bi-annual', 'quarterly')
  GROUP BY cp.cp_type, i.i_category, i.i_brand, cd.cd_gender, cd.cd_marital_status
)
SELECT
  cp_type,
  i_category,
  i_brand,
  cd_gender,
  cd_marital_status,
  total_profit,
  total_sales,
  avg_discount,
  distinct_customers,
  RANK() OVER (PARTITION BY cp_type ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
WHERE total_profit > 10000
ORDER BY cp_type, profit_rank
LIMIT 50
