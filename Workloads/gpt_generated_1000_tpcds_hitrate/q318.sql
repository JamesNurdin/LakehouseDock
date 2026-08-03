WITH recent_dates AS (
    SELECT d_date_sk, d_year
    FROM   date_dim
    WHERE  d_year = 2001
),
max_catalog_price AS (
    SELECT MAX(cs_ext_sales_price) AS max_price
    FROM   catalog_sales
)
SELECT sale_year,
       item_id,
       total_sales,
       source
FROM (
    SELECT d.d_year AS sale_year,
           i.i_item_id AS item_id,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           'catalog' AS source
    FROM   catalog_sales cs
    JOIN   recent_dates d
           ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN   item i
           ON cs.cs_item_sk = i.i_item_sk
    -- keep only medium sized items
    WHERE  i.i_size = 'medium'
    -- exclude any sales that have a matching return (anti‑join)
    AND    NOT EXISTS (
               SELECT 1
               FROM   catalog_returns cr
               WHERE  cr.cr_order_number = cs.cs_order_number
               AND    cr.cr_item_sk = cs.cs_item_sk
           )
    GROUP BY d.d_year, i.i_item_id
    HAVING SUM(cs.cs_ext_sales_price) > (
               SELECT AVG(cs2.cs_ext_sales_price)
               FROM   catalog_sales cs2
           )
    UNION ALL
    SELECT d.d_year AS sale_year,
           i.i_item_id AS item_id,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           'web' AS source
    FROM   web_sales ws
    JOIN   recent_dates d
           ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN   item i
           ON ws.ws_item_sk = i.i_item_sk
    -- keep only items whose class appears among large items (scalar subquery in IN)
    WHERE  i.i_class_id IN (
               SELECT i2.i_class_id
               FROM   item i2
               WHERE  i2.i_size = 'large'
           )
    GROUP BY d.d_year, i.i_item_id
    HAVING SUM(ws.ws_ext_sales_price) > (
               SELECT MAX(cs3.cs_ext_sales_price)
               FROM   catalog_sales cs3
           )
) AS combined
ORDER BY sale_year ASC,
         total_sales DESC
