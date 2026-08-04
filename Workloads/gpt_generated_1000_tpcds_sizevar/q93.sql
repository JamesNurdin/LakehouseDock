WITH store_agg AS (
   SELECT sr_item_sk,
          sr_hdemo_sk,
          sr_addr_sk,
          sr_return_time_sk,
          SUM(sr_return_amt) AS store_return_amt,
          AVG(sr_return_tax) AS avg_return_tax,
          COUNT(*) AS store_return_cnt
   FROM store_returns TABLESAMPLE BERNOULLI (20)
   WHERE sr_return_quantity > 1
     AND sr_return_ship_cost < 500
   GROUP BY sr_item_sk, sr_hdemo_sk, sr_addr_sk, sr_return_time_sk
),
web_agg AS (
   SELECT wr_item_sk,
          wr_refunded_hdemo_sk,
          wr_refunded_addr_sk,
          wr_returned_time_sk,
          wr_web_page_sk,
          SUM(wr_return_amt) AS web_return_amt,
          AVG(wr_return_tax) AS avg_web_tax,
          COUNT(*) AS web_return_cnt
   FROM web_returns
   WHERE wr_return_quantity > 0
     AND wr_return_ship_cost < 300
   GROUP BY wr_item_sk, wr_refunded_hdemo_sk, wr_refunded_addr_sk, wr_returned_time_sk, wr_web_page_sk
)
SELECT
  item.i_item_id,
  item.i_brand,
  promotion.p_promo_name,
  time_dim.t_hour,
  household_demographics.hd_income_band_sk,
  customer_address.ca_state,
  store_agg.store_return_amt,
  store_agg.avg_return_tax,
  store_agg.store_return_cnt,
  CAST(NULL AS decimal(7,2)) AS web_return_amt,
  CAST(NULL AS decimal(7,2)) AS avg_web_tax,
  CAST(NULL AS integer) AS web_return_cnt,
  ROW_NUMBER() OVER (ORDER BY store_agg.store_return_amt DESC) AS rn
FROM store_agg
JOIN item ON store_agg.sr_item_sk = item.i_item_sk
JOIN promotion ON promotion.p_item_sk = item.i_item_sk
JOIN time_dim ON store_agg.sr_return_time_sk = time_dim.t_time_sk
JOIN household_demographics ON store_agg.sr_hdemo_sk = household_demographics.hd_demo_sk
JOIN customer_address ON store_agg.sr_addr_sk = customer_address.ca_address_sk
WHERE item.i_current_price BETWEEN 10 AND 100
  AND item.i_brand_id IN (6008007, 1003001)
  AND customer_address.ca_state = 'CA'
  AND time_dim.t_hour BETWEEN 9 AND 17
  AND promotion.p_discount_active = 'Y'
UNION DISTINCT
SELECT
  item.i_item_id,
  item.i_brand,
  promotion.p_promo_name,
  time_dim.t_hour,
  household_demographics.hd_income_band_sk,
  customer_address.ca_state,
  CAST(NULL AS decimal(7,2)) AS store_return_amt,
  CAST(NULL AS decimal(7,2)) AS avg_return_tax,
  CAST(NULL AS integer) AS store_return_cnt,
  web_agg.web_return_amt,
  web_agg.avg_web_tax,
  web_agg.web_return_cnt,
  ROW_NUMBER() OVER (ORDER BY web_agg.web_return_amt DESC) AS rn
FROM web_agg
JOIN item ON web_agg.wr_item_sk = item.i_item_sk
JOIN promotion ON promotion.p_item_sk = item.i_item_sk
JOIN time_dim ON web_agg.wr_returned_time_sk = time_dim.t_time_sk
JOIN household_demographics ON web_agg.wr_refunded_hdemo_sk = household_demographics.hd_demo_sk
JOIN customer_address ON web_agg.wr_refunded_addr_sk = customer_address.ca_address_sk
JOIN web_page ON web_agg.wr_web_page_sk = web_page.wp_web_page_sk
WHERE item.i_current_price BETWEEN 10 AND 100
  AND item.i_manufact_id = 212
  AND web_page.wp_type = 'product'
  AND customer_address.ca_country = 'United States'
  AND time_dim.t_meal_time = 'Lunch'
ORDER BY rn
LIMIT 100
