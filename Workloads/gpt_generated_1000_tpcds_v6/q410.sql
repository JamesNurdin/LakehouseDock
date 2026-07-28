WITH high_price_items AS (
    SELECT i_item_sk, i_product_name, i_current_price
    FROM item
    WHERE i_current_price > 100
)

SELECT *
FROM (
   SELECT
       c.c_customer_id AS customer_id,
       hp.i_product_name AS product_name,
       SUM(ss.ss_net_profit) AS net_amount,
       'sale' AS source,
       (
           SELECT AVG(ss2.ss_ext_sales_price)
           FROM store_sales ss2
           WHERE ss2.ss_item_sk = hp.i_item_sk
       ) AS avg_sales_price
   FROM store_sales ss
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN high_price_items hp
     ON ss.ss_item_sk = hp.i_item_sk
   WHERE c.c_birth_country = 'KOREA'
     AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
   GROUP BY c.c_customer_id, hp.i_product_name, hp.i_item_sk
   UNION ALL
   SELECT
       c.c_customer_id AS customer_id,
       hp.i_product_name AS product_name,
       SUM(wr.wr_net_loss) AS net_amount,
       'return' AS source,
       (
           SELECT AVG(ss2.ss_ext_sales_price)
           FROM store_sales ss2
           WHERE ss2.ss_item_sk = hp.i_item_sk
       ) AS avg_sales_price
   FROM web_returns wr
   JOIN customer c
     ON wr.wr_returning_customer_sk = c.c_customer_sk
   JOIN high_price_items hp
     ON wr.wr_item_sk = hp.i_item_sk
   WHERE c.c_birth_country = 'KOREA'
     AND wr.wr_return_tax > 20.0
   GROUP BY c.c_customer_id, hp.i_product_name, hp.i_item_sk
) AS combined
ORDER BY net_amount DESC
LIMIT 100
