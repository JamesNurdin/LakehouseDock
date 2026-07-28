WITH filtered_sales AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_wholesale_cost,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_item_sk
    FROM store_sales ss
    WHERE ss.ss_wholesale_cost > 50
      AND ss.ss_ext_discount_amt < 3000
      AND ss.ss_ext_sales_price BETWEEN 1000 AND 10000
      AND ss.ss_quantity >= 1
      AND ss.ss_net_profit > 0
      AND EXISTS (
          SELECT 1
          FROM store_sales s2
          WHERE s2.ss_item_sk = ss.ss_item_sk
            AND s2.ss_ext_sales_price > 8000
          LIMIT 1
      )
)
SELECT
    cd.cd_gender,
    cd.cd_education_status,
    COUNT(DISTINCT f.ss_customer_sk) AS customer_cnt,
    SUM(f.ss_net_profit) AS total_profit,
    AVG(f.ss_ext_discount_amt) AS avg_discount,
    MIN(f.ss_wholesale_cost) AS min_wholesale_cost,
    MAX(f.ss_wholesale_cost) AS max_wholesale_cost
FROM filtered_sales f
JOIN customer_demographics cd
  ON f.ss_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_dep_count BETWEEN 1 AND 5
  AND cd.cd_dep_college_count IN (0, 1, 2)
  AND cd.cd_credit_rating = 'Good'
  AND cd.cd_marital_status = 'M'
  AND cd.cd_gender = 'F'
GROUP BY cd.cd_gender, cd.cd_education_status
ORDER BY total_profit DESC
LIMIT 100
