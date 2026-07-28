WITH store_agg AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       AVG(ss.ss_ext_discount_amt) AS avg_discount,
       COUNT(*) AS txn_count,
       ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank,
       (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_item_id = i.i_item_id) AS max_price
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE cd.cd_credit_rating = 'Low Risk'
     AND hd.hd_income_band_sk IN (
         SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound >= 50000
     )
     AND NOT EXISTS (
         SELECT 1 FROM web_sales ws
         WHERE ws.ws_item_sk = ss.ss_item_sk
           AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
     )
   GROUP BY i.i_item_id, i.i_product_name
   HAVING SUM(ss.ss_ext_sales_price) > 10000
),

web_agg AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       AVG(ws.ws_ext_discount_amt) AS avg_discount,
       COUNT(*) AS txn_count,
       ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
       (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_item_id = i.i_item_id) AS max_price
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cd.cd_education_status = 'College'
     AND hd.hd_vehicle_count > 0
     AND EXISTS (
         SELECT 1 FROM store_sales ss
         WHERE ss.ss_item_sk = ws.ws_item_sk
           AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
     )
   GROUP BY i.i_item_id, i.i_product_name
   HAVING SUM(ws.ws_ext_sales_price) > 8000
)

SELECT
    i_item_id,
    i_product_name,
    total_sales,
    avg_discount,
    txn_count,
    sales_rank,
    max_price
FROM (
    SELECT i_item_id, i_product_name, total_sales, avg_discount, txn_count, sales_rank, max_price
    FROM store_agg
    UNION ALL
    SELECT i_item_id, i_product_name, total_sales, avg_discount, txn_count, sales_rank, max_price
    FROM web_agg
) combined
ORDER BY total_sales DESC, sales_rank
LIMIT 100
