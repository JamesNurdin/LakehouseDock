WITH joined_data AS (
   SELECT
       cd.cd_gender,
       cd.cd_marital_status,
       ss.ss_ext_sales_price,
       ss.ss_sales_price,
       ss.ss_ticket_number,
       sr.sr_return_amt,
       sr.sr_reversed_charge,
       sr.sr_return_quantity,
       wr.wr_return_amt,
       wr.wr_return_ship_cost,
       wr.wr_return_quantity
   FROM store_sales ss
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
),
agg_a AS (
   SELECT
       cd_gender,
       cd_marital_status,
       SUM(ss_ext_sales_price) AS total_sales,
       SUM(sr_return_amt) AS total_store_return,
       SUM(wr_return_amt) AS total_web_return,
       AVG(sr_reversed_charge) AS avg_rev_charge,
       COUNT(DISTINCT ss_ticket_number) AS cnt_transactions
   FROM joined_data
   WHERE cd_gender = 'M'
     AND cd_marital_status = 'M'
     AND sr_reversed_charge > 100
     AND sr_return_quantity >= 2
     AND ss_sales_price > 50
     AND wr_return_ship_cost < 200
   GROUP BY cd_gender, cd_marital_status
),
agg_b AS (
   SELECT
       cd_gender,
       cd_marital_status,
       SUM(ss_ext_sales_price) AS total_sales,
       SUM(sr_return_amt) AS total_store_return,
       SUM(wr_return_amt) AS total_web_return,
       AVG(sr_reversed_charge) AS avg_rev_charge,
       COUNT(DISTINCT ss_ticket_number) AS cnt_transactions
   FROM joined_data
   WHERE cd_gender = 'F'
     AND cd_marital_status = 'S'
     AND sr_reversed_charge <= 50
     AND sr_return_quantity = 1
     AND ss_sales_price <= 30
     AND wr_return_ship_cost > 300
   GROUP BY cd_gender, cd_marital_status
)
SELECT
   cd_gender,
   cd_marital_status,
   total_sales,
   total_store_return,
   total_web_return,
   avg_rev_charge,
   cnt_transactions,
   SUM(total_sales) OVER (PARTITION BY cd_gender) AS sales_by_gender_total,
   RANK() OVER (ORDER BY (total_sales + total_store_return + total_web_return) DESC) AS rank_by_total_amount
FROM (
   SELECT * FROM agg_a
   UNION ALL
   SELECT * FROM agg_b
) u
ORDER BY rank_by_total_amount
LIMIT 100
