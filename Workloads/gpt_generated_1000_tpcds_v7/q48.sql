WITH avg_list_price AS (
    SELECT avg(ss_ext_list_price) AS avg_price
    FROM store_sales
)
SELECT
    cd.cd_gender,
    cd.cd_credit_rating,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(*) AS transactions,
    (SELECT avg_price FROM avg_list_price) AS overall_avg_price
FROM store_sales ss
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'Good'
  AND ss.ss_ext_list_price > 5000
GROUP BY cd.cd_gender, cd.cd_credit_rating
HAVING SUM(ss.ss_ext_sales_price) > 10000

UNION ALL

SELECT
    cd2.cd_gender,
    cd2.cd_credit_rating,
    SUM(ss2.ss_ext_sales_price) AS total_sales,
    COUNT(*) AS transactions,
    (SELECT avg_price FROM avg_list_price) AS overall_avg_price
FROM store_sales ss2
JOIN customer_demographics cd2 ON ss2.ss_cdemo_sk = cd2.cd_demo_sk
WHERE cd2.cd_credit_rating = 'Low Risk'
  AND ss2.ss_ext_tax < 200
  AND EXISTS (
        SELECT 1
        FROM store_sales ss3
        WHERE ss3.ss_customer_sk = ss2.ss_customer_sk
          AND ss3.ss_ext_sales_price > 2000
        LIMIT 1
      )
GROUP BY cd2.cd_gender, cd2.cd_credit_rating
HAVING COUNT(*) >= 5
ORDER BY total_sales DESC
LIMIT 100
