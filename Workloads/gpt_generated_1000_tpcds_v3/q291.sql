SELECT
    cd.cd_gender,
    cd.cd_credit_rating,
    SUM(DISTINCT ss.ss_ext_sales_price) AS total_distinct_sales
FROM store_sales ss
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'Good'
  AND ss.ss_ext_sales_price > 2000
GROUP BY cd.cd_gender, cd.cd_credit_rating
ORDER BY total_distinct_sales DESC
LIMIT 100
