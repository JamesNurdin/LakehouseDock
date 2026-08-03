WITH
  cat_agg AS (
    SELECT
      cs.cs_bill_cdemo_sk AS demo_sk,
      SUM(cs.cs_ext_sales_price) AS cat_sales_total,
      AVG(cs.cs_ext_sales_price) AS cat_sales_avg,
      COUNT(*) AS cat_sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_list_price > 50
      AND cs.cs_quantity >= 2
      AND cs.cs_ship_customer_sk IN (3089367, 3851857)
    GROUP BY cs.cs_bill_cdemo_sk
  ),
  store_agg AS (
    SELECT
      ss.ss_cdemo_sk AS demo_sk,
      SUM(ss.ss_ext_sales_price) AS store_sales_total,
      AVG(ss.ss_ext_sales_price) AS store_sales_avg,
      COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    WHERE ss.ss_net_paid_inc_tax > 500
      AND ss.ss_quantity BETWEEN 1 AND 5
      AND ss.ss_store_sk = 7
    GROUP BY ss.ss_cdemo_sk
  ),
  common_demo AS (
    SELECT demo_sk FROM cat_agg
    INTERSECT
    SELECT demo_sk FROM store_agg
  ),
  union_sales AS (
    SELECT demo_sk, cat_sales_total AS sales_amt, cat_sales_cnt AS sales_cnt, 'catalog' AS src
    FROM cat_agg
    UNION
    SELECT demo_sk, store_sales_total, store_sales_cnt, 'store' AS src
    FROM store_agg
  ),
  final AS (
    SELECT
      cd.cd_demo_sk,
      cd.cd_gender,
      cd.cd_marital_status,
      cd.cd_education_status,
      COALESCE(cat_agg.cat_sales_total, 0) AS cat_sales_total,
      COALESCE(store_agg.store_sales_total, 0) AS store_sales_total,
      CASE
        WHEN COALESCE(cat_agg.cat_sales_total, 0) + COALESCE(store_agg.store_sales_total, 0) > 100000 THEN 'HIGH'
        ELSE 'LOW'
      END AS sales_category,
      (
        SELECT SUM(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_cdemo_sk = cd.cd_demo_sk
      ) AS total_store_net_profit
    FROM customer_demographics cd
    RIGHT OUTER JOIN cat_agg
      ON cd.cd_demo_sk = cat_agg.demo_sk
    LEFT JOIN store_agg
      ON cd.cd_demo_sk = store_agg.demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_college_count >= 3
  )
SELECT
  f.cd_demo_sk AS demo_sk,
  f.cd_gender,
  f.cd_marital_status,
  f.sales_category,
  f.cat_sales_total,
  f.store_sales_total,
  f.total_store_net_profit
FROM final f
JOIN common_demo cd_common
  ON f.cd_demo_sk = cd_common.demo_sk
ORDER BY f.cat_sales_total DESC, f.store_sales_total DESC
LIMIT 100
