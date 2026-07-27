WITH demo_sales AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_credit_rating,
        CONCAT(cd.cd_gender, '-', cd.cd_credit_rating) AS gender_rating_key,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_cnt,
        AVG(ss.ss_sales_price) AS avg_price,
        MAX(ss.ss_sales_price) AS max_price
    FROM store_sales ss
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE REGEXP_LIKE(cd.cd_credit_rating, '(?i)good|high risk')
      AND cd.cd_gender LIKE 'F%'
      AND REGEXP_EXTRACT(cd.cd_credit_rating, '(\\w+)') <> ''
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_credit_rating
)
SELECT
    ds.cd_demo_sk,
    ds.gender_rating_key,
    ds.total_sales,
    ds.txn_cnt,
    ds.avg_price,
    ds.max_price,
    CASE
        WHEN ds.total_sales >= 20000 THEN 'Platinum'
        WHEN ds.total_sales >= 10000 THEN 'Gold'
        ELSE 'Silver'
    END AS tier,
    (
        SELECT COUNT(*)
        FROM store_sales ss2
        WHERE ss2.ss_cdemo_sk = ds.cd_demo_sk
          AND ss2.ss_sales_price > 50
          AND ss2.ss_list_price < 200
    ) AS high_price_txn_cnt
FROM demo_sales ds
WHERE ds.txn_cnt >= 3
  AND EXISTS (
        SELECT 1
        FROM customer_demographics cd2
        WHERE cd2.cd_demo_sk = ds.cd_demo_sk
          AND cd2.cd_education_status LIKE '%College%'
    )
ORDER BY ds.total_sales DESC, ds.cd_demo_sk
LIMIT 100
