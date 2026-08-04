WITH max_sales_price AS (
   SELECT MAX(ss_ext_sales_price) AS max_price
   FROM store_sales
),
sales_demo AS (
   SELECT ss.ss_sold_date_sk AS date_sk,
          ss.ss_customer_sk AS customer_sk,
          ss.ss_cdemo_sk AS demo_sk,
          ss.ss_ext_sales_price,
          ss.ss_quantity,
          cd.cd_gender,
          cd.cd_dep_count
   FROM store_sales ss
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE ss.ss_ext_sales_price > 1000
     AND ss.ss_quantity > 1
     AND cd.cd_dep_count >= 2
     AND cd.cd_gender = 'M'
     AND ss.ss_ext_sales_price < 20000
     AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
),
returns_demo AS (
   SELECT wr.wr_returned_date_sk AS return_date_sk,
          wr.wr_refunded_cdemo_sk AS demo_sk,
          wr.wr_return_amt,
          wr.wr_account_credit,
          wr.wr_fee,
          cd.cd_gender,
          cd.cd_dep_count
   FROM web_returns wr
   JOIN customer_demographics cd
     ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE wr.wr_return_amt > 50
     AND wr.wr_fee < 100
     AND cd.cd_dep_count <= 5
     AND cd.cd_gender = 'F'
     AND wr.wr_return_quantity > 0
),
combined AS (
   SELECT sd.date_sk,
          sd.customer_sk,
          sd.demo_sk,
          sd.cd_gender,
          sd.cd_dep_count,
          sd.ss_ext_sales_price,
          rd.wr_return_amt,
          CASE WHEN sd.ss_ext_sales_price > (SELECT max_price FROM max_sales_price) THEN 1 ELSE 0 END AS high_price_flag
   FROM sales_demo sd
   LEFT JOIN returns_demo rd
     ON sd.demo_sk = rd.demo_sk
),
agg AS (
   SELECT
       date_sk,
       customer_sk,
       cd_gender,
       cd_dep_count,
       SUM(ss_ext_sales_price) AS total_sales,
       SUM(COALESCE(wr_return_amt, 0)) AS total_returns,
       SUM(high_price_flag) AS high_price_count
   FROM combined
   GROUP BY GROUPING SETS (
       (date_sk, customer_sk, cd_gender, cd_dep_count),
       (cd_gender, cd_dep_count),
       ()
   )
   HAVING SUM(ss_ext_sales_price) > 500
)
SELECT
    date_sk,
    customer_sk,
    cd_gender,
    cd_dep_count,
    total_sales,
    total_returns,
    high_price_count,
    ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS gender_sales_rank,
    RANK() OVER (ORDER BY total_sales DESC) AS overall_sales_rank
FROM agg
EXCEPT
SELECT
    date_sk,
    customer_sk,
    cd_gender,
    cd_dep_count,
    total_sales,
    total_returns,
    high_price_count,
    gender_sales_rank,
    overall_sales_rank
FROM (
    SELECT
        date_sk,
        customer_sk,
        cd_gender,
        cd_dep_count,
        total_sales,
        total_returns,
        high_price_count,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS gender_sales_rank,
        RANK() OVER (ORDER BY total_sales DESC) AS overall_sales_rank
    FROM agg
) t
WHERE overall_sales_rank > 10
ORDER BY overall_sales_rank
LIMIT 100
