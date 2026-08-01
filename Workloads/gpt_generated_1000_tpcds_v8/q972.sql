WITH
  sales_agg AS (
    SELECT
      cs_bill_cdemo_sk,
      SUM(cs_ext_sales_price) AS sum_ext_sales_price,
      SUM(cs_quantity) AS sum_quantity,
      COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE
      cs_ext_sales_price > 1000
      AND cs_list_price BETWEEN 80 AND 130
      AND cs_quantity >= 1
      AND cs_wholesale_cost > 20
      AND cs_coupon_amt < 50
    GROUP BY cs_bill_cdemo_sk
  ),
  demo_keys_intersect AS (
    SELECT cs_bill_cdemo_sk AS demo_sk FROM catalog_sales WHERE cs_ext_discount_amt > 0
    INTERSECT
    SELECT cs_ship_cdemo_sk AS demo_sk FROM catalog_sales WHERE cs_ext_tax > 0
  ),
  joined AS (
    SELECT
      cd.cd_demo_sk,
      cd.cd_gender,
      cd.cd_education_status,
      cd.cd_dep_college_count,
      COALESCE(sa.sum_ext_sales_price, 0) AS total_sales_price,
      COALESCE(sa.sum_quantity, 0) AS total_quantity,
      COALESCE(sa.sales_cnt, 0) AS total_transactions
    FROM sales_agg sa
    RIGHT OUTER JOIN customer_demographics cd
      ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN demo_keys_intersect dki
      ON cd.cd_demo_sk = dki.demo_sk
    WHERE
      cd.cd_education_status IN ('College', 'Advanced Degree', '4 yr Degree')
      AND cd.cd_dep_college_count >= 1
      AND cd.cd_purchase_estimate >= 2000
      AND cd.cd_credit_rating IS NOT NULL
      AND cd.cd_marital_status = 'M'
  ),
  agg AS (
    SELECT
      j.cd_demo_sk,
      j.cd_gender,
      j.cd_education_status,
      j.cd_dep_college_count,
      SUM(j.total_sales_price) AS sum_sales_price,
      SUM(j.total_quantity) AS sum_quantity,
      SUM(j.total_transactions) AS sum_transactions
    FROM joined j
    GROUP BY CUBE(j.cd_gender, j.cd_education_status, j.cd_demo_sk, j.cd_dep_college_count)
  )
SELECT
  a.cd_demo_sk,
  a.cd_gender,
  a.cd_education_status,
  a.cd_dep_college_count,
  a.sum_sales_price,
  a.sum_quantity,
  a.sum_transactions,
  (
    SELECT SUM(cs_ext_sales_price)
    FROM catalog_sales cs
    WHERE cs.cs_bill_cdemo_sk = a.cd_demo_sk
  ) AS overall_sales_price,
  ROW_NUMBER() OVER (PARTITION BY a.cd_gender ORDER BY a.sum_sales_price DESC) AS gender_rank
FROM agg a
ORDER BY a.cd_gender, gender_rank
LIMIT 100
