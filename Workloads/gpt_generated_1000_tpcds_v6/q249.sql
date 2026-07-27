WITH sales AS (
   SELECT
       i.i_product_name AS product,
       cs.cs_sold_date_sk AS date_key,
       cs.cs_ext_sales_price AS amount,
       'sale' AS txn_type
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE t.t_meal_time = 'dinner'
     AND cs.cs_ext_sales_price > 100
),
returns AS (
   SELECT
       i.i_product_name AS product,
       sr.sr_returned_date_sk AS date_key,
       -sr.sr_return_amt AS amount,
       'return' AS txn_type
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE t.t_meal_time = 'dinner'
     AND sr.sr_return_amt > 50
     AND EXISTS (
         SELECT 1
         FROM catalog_sales cs2
         JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
         WHERE i2.i_item_sk = sr.sr_item_sk
           AND cs2.cs_ext_sales_price > 200
     )
)
SELECT
    product,
    date_key,
    amount,
    txn_type
FROM sales
UNION ALL
SELECT
    product,
    date_key,
    amount,
    txn_type
FROM returns
ORDER BY amount DESC, product ASC
LIMIT 100
