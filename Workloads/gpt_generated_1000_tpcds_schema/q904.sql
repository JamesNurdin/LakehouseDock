WITH
  store_sales_agg AS (
    SELECT
      i.i_item_id,
      s.s_store_name AS store_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt,
      CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Other' END AS marital_group
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_state = 'CA'
      AND cd.cd_education_status = 'College'
    GROUP BY i.i_item_id, s.s_store_name, cd.cd_marital_status
  ),
  catalog_sales_agg AS (
    SELECT
      i.i_item_id,
      cp.cp_department AS store_name,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt,
      CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS marital_group
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_type = 'Promotion'
      AND cd.cd_gender = 'M'
      AND cs.cs_item_sk IN (
        SELECT i2.i_item_sk FROM item i2 WHERE i2.i_color = 'red'
      )
    GROUP BY i.i_item_id, cp.cp_department, cd.cd_gender
  ),
  combined AS (
    SELECT i_item_id, store_name, total_sales, sales_cnt, marital_group
    FROM store_sales_agg
    UNION ALL
    SELECT i_item_id, store_name, total_sales, sales_cnt, marital_group
    FROM catalog_sales_agg
  )
SELECT
  i_item_id,
  store_name,
  total_sales,
  sales_cnt,
  marital_group,
  LAG(total_sales) OVER (PARTITION BY i_item_id ORDER BY total_sales DESC) AS prev_sales,
  SUM(total_sales) OVER (PARTITION BY i_item_id ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM combined
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
