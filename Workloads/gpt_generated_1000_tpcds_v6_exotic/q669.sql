WITH filtered_items AS (
    SELECT i.i_item_sk,
           i.i_category,
           i.i_current_price
    FROM   item i
    WHERE  i.i_current_price > (
               SELECT AVG(i2.i_current_price)
               FROM   item i2
               WHERE  i2.i_category = 'Sports'
           )
)
SELECT d.d_year,
       d.d_month_seq         AS month,
       'store'               AS sales_channel,
       SUM(ss.ss_net_paid)  AS total_net_paid
FROM   store_sales ss
JOIN   date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN   filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
WHERE  d.d_year = 2002
  AND EXISTS (
        SELECT 1
        FROM   store s
        WHERE  s.s_store_sk = ss.ss_store_sk
          AND  s.s_closed_date_sk IS NULL
      )
GROUP BY d.d_year, d.d_month_seq
UNION ALL
SELECT d.d_year,
       d.d_month_seq         AS month,
       'catalog'             AS sales_channel,
       SUM(cs.cs_net_paid)  AS total_net_paid
FROM   catalog_sales cs
JOIN   date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN   filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
WHERE  d.d_year = 2002
  AND EXISTS (
        SELECT 1
        FROM   call_center cc
        WHERE  cc.cc_call_center_sk = cs.cs_call_center_sk
          AND  cc.cc_open_date_sk IS NOT NULL
      )
GROUP BY d.d_year, d.d_month_seq
ORDER BY d_year DESC,
         month DESC,
         sales_channel
LIMIT 100
