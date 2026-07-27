WITH sales_data AS (
   SELECT DISTINCT
       c.c_customer_id,
       i.i_item_id,
       ss.ss_sold_date_sk AS date_sk,
       ss.ss_net_profit AS profit,
       (SELECT avg(i2.i_current_price) FROM item i2 WHERE i2.i_brand = i.i_brand) AS brand_avg_price
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND ss.ss_net_profit > 20
     AND EXISTS (
         SELECT 1
         FROM promotion p
         WHERE p.p_promo_sk = ss.ss_promo_sk
           AND p.p_discount_active = 'Y'
     )
),
returns_data AS (
   SELECT DISTINCT
       c.c_customer_id,
       i.i_item_id,
       sr.sr_returned_date_sk AS date_sk,
       -sr.sr_net_loss AS profit,
       (SELECT avg(i2.i_current_price) FROM item i2 WHERE i2.i_brand = i.i_brand) AS brand_avg_price
   FROM store_returns sr
   JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND sr.sr_net_loss > 10
     AND i.i_current_price > 50
)
SELECT *
FROM sales_data
UNION ALL
SELECT *
FROM returns_data
ORDER BY profit DESC
LIMIT 100
