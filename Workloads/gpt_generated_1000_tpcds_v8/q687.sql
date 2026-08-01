WITH sampled_sales AS (
   SELECT ss.*
   FROM store_sales ss
   TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_item_sk,
       ss.ss_sales_price,
       ss.ss_quantity,
       i.i_brand,
       i.i_category,
       cd.cd_gender,
       hd.hd_buy_potential,
       ib.ib_upper_bound,
       r.r_reason_desc,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       sr.sr_ticket_number
   FROM sampled_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE i.i_current_price > 20.00
     AND cd.cd_gender = 'M'
     AND hd.hd_buy_potential = '5001-10000'
     AND ib.ib_upper_bound <= 80000
     AND r.r_reason_desc LIKE '%defect%'
     AND sr.sr_return_quantity >= 30
),
scalar_sub AS (
   SELECT i_item_sk
   FROM item
   WHERE i_brand = 'BrandX'
   LIMIT 1
),
intersect_set AS (
   SELECT sr_ticket_number AS ticket_num
   FROM store_returns
   WHERE sr_return_quantity > 30
   INTERSECT
   SELECT ss_ticket_number AS ticket_num
   FROM store_sales
   WHERE ss_quantity > 5
),
except_set AS (
   SELECT sr_ticket_number AS ticket_num
   FROM store_returns
   WHERE sr_return_amt > 100
   EXCEPT
   SELECT ss_ticket_number AS ticket_num
   FROM store_sales
   WHERE ss_quantity < 2
)
SELECT
   jd.i_brand,
   jd.i_category,
   jd.cd_gender,
   jd.hd_buy_potential,
   SUM(jd.sr_return_amt) AS total_return_amount,
   AVG(jd.ss_sales_price) AS avg_sales_price,
   COUNT(DISTINCT jd.ss_ticket_number) AS num_transactions,
   MIN(jd.sr_return_quantity) AS min_return_qty,
   MAX(jd.sr_return_quantity) AS max_return_qty
FROM joined_data jd
WHERE jd.ss_item_sk = (SELECT i_item_sk FROM scalar_sub)
  AND jd.ss_ticket_number IN (SELECT ticket_num FROM intersect_set)
  AND jd.ss_ticket_number NOT IN (SELECT ticket_num FROM except_set)
GROUP BY jd.i_brand, jd.i_category, jd.cd_gender, jd.hd_buy_potential
HAVING SUM(jd.sr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
