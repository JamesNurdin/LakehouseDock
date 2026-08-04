WITH ss_agg AS (
   SELECT
      ss_item_sk,
      ss_store_sk,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_quantity)       AS total_qty
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
   WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450600
     AND ss_sales_price > 20.0
     AND ss_wholesale_cost < 50.0
     AND ss_coupon_amt IS NOT NULL
   GROUP BY ss_item_sk, ss_store_sk
),
cr_agg AS (
   SELECT
      cr_item_sk,
      SUM(cr_net_loss) AS total_loss,
      COUNT(*)          AS return_cnt
   FROM catalog_returns
   WHERE cr_return_quantity > 0
     AND cr_return_amount > 100.0
     AND cr_fee < 10.0
     AND cr_returned_date_sk BETWEEN 2450000 AND 2450600
     AND cr_reversed_charge > 20.0
   GROUP BY cr_item_sk
)
SELECT
   i.i_item_id,
   i.i_product_name,
   i.i_current_price,
   i.i_brand,
   hd.hd_buy_potential,
   cd.cd_gender,
   cd.cd_education_status,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   ss_agg.total_sales,
   ss_agg.total_qty,
   cr_agg.total_loss,
   cr_agg.return_cnt,
   ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss_agg.total_sales DESC) AS category_row_num,
   RANK()       OVER (ORDER BY cr_agg.total_loss DESC)                 AS loss_rank
FROM ss_agg
JOIN store_sales ss
  ON ss.ss_item_sk = ss_agg.ss_item_sk
 AND ss.ss_store_sk = ss_agg.ss_store_sk
JOIN item i
  ON i.i_item_sk = ss_agg.ss_item_sk
JOIN cr_agg
  ON cr_agg.cr_item_sk = i.i_item_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
JOIN income_band ib
  ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
WHERE i.i_current_price BETWEEN 10 AND 100
  AND i.i_brand LIKE '%bar%'
  AND cd.cd_credit_rating = 'Excellent'
  AND hd.hd_vehicle_count > 1
  AND ib.ib_upper_bound <= 190000
ORDER BY loss_rank, category_row_num
LIMIT 100
