WITH daily_sales AS (
    SELECT ss_store_sk,
           ss_item_sk,
           ss_sold_date_sk,
           SUM(ss_net_paid) AS daily_net_paid,
           SUM(ss_quantity) AS daily_quantity
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 20200101 AND 20200131
      AND ss_ext_discount_amt > 0
    GROUP BY ss_store_sk, ss_item_sk, ss_sold_date_sk
)
SELECT d1.ss_store_sk,
       d1.ss_item_sk,
       d1.ss_sold_date_sk AS day1,
       d2.ss_sold_date_sk AS day2,
       d1.daily_net_paid AS net_paid_day1,
       d2.daily_net_paid AS net_paid_day2,
       (d2.daily_net_paid - d1.daily_net_paid) / NULLIF(d1.daily_net_paid, 0) AS pct_change,
       RANK() OVER (PARTITION BY d1.ss_store_sk ORDER BY (d2.daily_net_paid - d1.daily_net_paid) DESC) AS sales_growth_rank
FROM daily_sales d1
JOIN daily_sales d2
  ON d1.ss_store_sk = d2.ss_store_sk
 AND d1.ss_item_sk = d2.ss_item_sk
 AND d2.ss_sold_date_sk = d1.ss_sold_date_sk + 1
WHERE d1.daily_net_paid > 0
ORDER BY d1.ss_store_sk, pct_change DESC
LIMIT 100
