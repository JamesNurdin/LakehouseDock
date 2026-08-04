WITH catalog_agg AS (
   SELECT
       c.c_customer_id AS customer_id,
       d.d_year AS sales_year,
       cd.cd_gender AS gender,
       SUM(cs.cs_ext_sales_price) AS sales_amount,
       MAX(item_qty.total_qty) AS item_total_qty
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   CROSS JOIN LATERAL (
       SELECT SUM(cs2.cs_quantity) AS total_qty
       FROM catalog_sales cs2
       WHERE cs2.cs_item_sk = cs.cs_item_sk
   ) AS item_qty
   WHERE d.d_year = 2001
     AND cd.cd_gender = 'M'
   GROUP BY GROUPING SETS (
       (c.c_customer_id, d.d_year, cd.cd_gender),
       (d.d_year, cd.cd_gender),
       (c.c_customer_id)
   )
   HAVING SUM(cs.cs_ext_sales_price) > 10000
),
web_agg AS (
   SELECT
       c.c_customer_id AS customer_id,
       d.d_year AS sales_year,
       cd.cd_gender AS gender,
       SUM(ws.ws_ext_sales_price) AS sales_amount,
       MAX(item_qty.total_qty) AS item_total_qty
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   CROSS JOIN LATERAL (
       SELECT SUM(ws2.ws_quantity) AS total_qty
       FROM web_sales ws2
       WHERE ws2.ws_item_sk = ws.ws_item_sk
   ) AS item_qty
   WHERE d.d_year = 2002
     AND cd.cd_gender = 'F'
   GROUP BY GROUPING SETS (
       (c.c_customer_id, d.d_year, cd.cd_gender),
       (d.d_year, cd.cd_gender),
       (c.c_customer_id)
   )
   HAVING SUM(ws.ws_ext_sales_price) > 15000
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
LIMIT 100
