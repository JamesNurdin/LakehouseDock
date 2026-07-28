WITH catalog AS (
   SELECT cs.cs_order_number AS order_number,
          d.d_date AS sold_date,
          cs.cs_net_paid AS sales_amount,
          i.i_category AS item_category,
          'catalog' AS sales_channel
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2002
     AND cs.cs_quantity > 1
),
web AS (
   SELECT ws.ws_order_number AS order_number,
          d.d_date AS sold_date,
          ws.ws_net_paid AS sales_amount,
          i.i_category AS item_category,
          'web' AS sales_channel
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2002
     AND ws.ws_quantity > 1
)
SELECT order_number,
       sold_date,
       sales_amount,
       item_category,
       sales_channel
FROM catalog
UNION ALL
SELECT order_number,
       sold_date,
       sales_amount,
       item_category,
       sales_channel
FROM web
ORDER BY sales_amount DESC
LIMIT 100
