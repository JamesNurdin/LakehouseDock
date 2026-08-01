WITH sampled_sales AS (
  SELECT *
  FROM store_sales
  TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows
),
full_data AS (
  SELECT
    ss.ss_cdemo_sk,
    cd.cd_demo_sk AS cd_demo_sk,
    ss.ss_ext_sales_price,
    ss.ss_ext_discount_amt,
    cd.cd_gender,
    cd.cd_credit_rating,
    cd.cd_dep_college_count
  FROM sampled_sales ss
  FULL OUTER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
),
agg_a AS (
  SELECT
    cd_gender,
    cd_demo_sk,
    SUM(ss_ext_sales_price) AS total_sales,
    CASE WHEN SUM(ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
  FROM full_data
  WHERE cd_credit_rating = 'Excellent' OR cd_credit_rating IS NULL
  GROUP BY cd_gender, cd_demo_sk
  HAVING COUNT(*) >= 5
),
agg_b AS (
  SELECT
    cd_gender,
    cd_demo_sk,
    SUM(ss_ext_sales_price) AS total_sales,
    CASE WHEN SUM(ss_ext_sales_price) > 50000 THEN 'MEDIUM' ELSE 'LOW' END AS sales_category
  FROM full_data
  WHERE cd_dep_college_count > 2
  GROUP BY cd_gender, cd_demo_sk
  HAVING COUNT(*) >= 3
),
intersect_genders AS (
  SELECT cd_gender FROM agg_a
  INTERSECT
  SELECT cd_gender FROM agg_b
),
except_genders AS (
  SELECT cd_gender FROM agg_a
  EXCEPT
  SELECT cd_gender FROM agg_b
),
final AS (
  SELECT
    a.cd_gender,
    a.cd_demo_sk,
    a.total_sales,
    a.sales_category,
    (
      SELECT MAX(ss2.ss_ext_sales_price)
      FROM store_sales ss2
      WHERE ss2.ss_cdemo_sk = a.cd_demo_sk
    ) AS max_sales_for_demo
  FROM agg_a a
  WHERE a.cd_gender IN (SELECT cd_gender FROM intersect_genders)
)
SELECT
  f.cd_gender,
  f.total_sales,
  f.sales_category,
  f.max_sales_for_demo
FROM final f
ORDER BY f.total_sales DESC
LIMIT 100
