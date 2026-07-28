WITH catalog_sales_agg AS (
    SELECT d.d_date AS sale_date,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND cs.cs_ext_sales_price > (
          SELECT AVG(cs2.cs_ext_sales_price)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
      )
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
    GROUP BY d.d_date
),
web_sales_agg AS (
    SELECT d.d_date AS sale_date,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND ws.ws_ext_sales_price > (
          SELECT AVG(ws2.ws_ext_sales_price)
          FROM web_sales ws2
          WHERE ws2.ws_sold_date_sk = ws.ws_sold_date_sk
      )
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
      )
    GROUP BY d.d_date
)
SELECT sale_date,
       total_sales,
       channel
FROM catalog_sales_agg
UNION ALL
SELECT sale_date,
       total_sales,
       channel
FROM web_sales_agg
LIMIT 100
