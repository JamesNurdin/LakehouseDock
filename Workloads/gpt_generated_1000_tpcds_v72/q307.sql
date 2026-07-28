WITH sales_agg AS (
    SELECT
        ss_cdemo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_qty,
        AVG(ss_list_price) AS avg_list_price,
        MIN(ss_sold_date_sk) AS first_sold_date_sk,
        MAX(ss_sold_date_sk) AS last_sold_date_sk
    FROM store_sales
    WHERE ss_list_price BETWEEN 20.00 AND 150.00
      AND ss_sold_date_sk BETWEEN 2451200 AND 2452300
    GROUP BY ss_cdemo_sk
)
SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    sa.total_sales,
    sa.total_qty,
    sa.avg_list_price,
    CASE WHEN cd.cd_credit_rating = 'Excellent' THEN 'HIGH' ELSE 'LOW' END AS credit_category
FROM sales_agg AS sa
LEFT OUTER JOIN customer_demographics AS cd
    ON sa.ss_cdemo_sk = cd.cd_demo_sk
WHERE (
        cd.cd_dep_employed_count >= 1 OR cd.cd_demo_sk IS NULL
      )
  AND (
        cd.cd_dep_college_count <= 3 OR cd.cd_demo_sk IS NULL
      )
  AND (
        cd.cd_purchase_estimate > (SELECT AVG(cd2.cd_purchase_estimate) FROM customer_demographics cd2)
        OR cd.cd_demo_sk IS NULL
      )
  AND EXISTS (
        SELECT 1
        FROM store_sales s2
        WHERE s2.ss_cdemo_sk = cd.cd_demo_sk
          AND s2.ss_ext_discount_amt > 10.00
      )
ORDER BY sa.total_sales DESC
LIMIT 100
