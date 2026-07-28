WITH ss AS (
   SELECT
       i.i_item_id AS item_id,
       i.i_product_name,
       substring(i.i_product_name, 1, 15) AS prod_prefix,
       SUM(ss.ss_ext_sales_price) AS sales_amount,
       COUNT(*) AS sales_cnt,
       (SELECT avg(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = i.i_category) AS avg_category_price
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   WHERE regexp_like(i.i_product_name, '(?i)blue')
     AND s.s_state LIKE 'C%'
     AND t.t_hour BETWEEN 9 AND 17
   GROUP BY i.i_item_id, i.i_product_name, i.i_category, substring(i.i_product_name, 1, 15), s.s_state
   HAVING SUM(ss.ss_ext_sales_price) > 500
),
ws AS (
   SELECT
       i.i_item_id AS item_id,
       i.i_product_name,
       substring(i.i_product_name, 1, 15) AS prod_prefix,
       SUM(ws.ws_ext_sales_price) AS sales_amount,
       COUNT(*) AS sales_cnt,
       (SELECT avg(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = i.i_category) AS avg_category_price
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   WHERE regexp_like(i.i_product_name, '(?i)red')
     AND EXISTS (
         SELECT 1
         FROM web_returns wr
         JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
         WHERE wr.wr_order_number = ws.ws_order_number
           AND r.r_reason_desc LIKE '%defect%'
     )
     AND t.t_meal_time = 'Dinner'
   GROUP BY i.i_item_id, i.i_product_name, i.i_category, substring(i.i_product_name, 1, 15)
   HAVING COUNT(*) >= 3
)
SELECT
   item_id,
   prod_prefix,
   sales_amount,
   sales_cnt,
   avg_category_price,
   CASE
       WHEN sales_amount > avg_category_price * 10 THEN 'High Performer'
       ELSE 'Normal'
   END AS performance_tag
FROM ss
UNION ALL
SELECT
   item_id,
   prod_prefix,
   sales_amount,
   sales_cnt,
   avg_category_price,
   CASE
       WHEN sales_amount > avg_category_price * 10 THEN 'High Performer'
       ELSE 'Normal'
   END AS performance_tag
FROM ws
ORDER BY sales_amount DESC
LIMIT 100
