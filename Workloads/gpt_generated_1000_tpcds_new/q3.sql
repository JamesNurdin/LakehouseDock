WITH catalog_part AS (
    SELECT
        CAST('Catalog' AS varchar) AS channel,
        d.d_year AS year,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2020
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
    GROUP BY d.d_year
),
web_part AS (
    SELECT
        CAST('Web' AS varchar) AS channel,
        d.d_year AS year,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_returns cr
          WHERE cr.cr_item_sk = ws.ws_item_sk
      )
    GROUP BY d.d_year
),
combined AS (
    SELECT * FROM catalog_part
    UNION ALL
    SELECT * FROM web_part
)
SELECT
    channel,
    year,
    total_sales
FROM combined
WHERE total_sales > (SELECT avg(cs_ext_sales_price) FROM tpcds.catalog_sales)
ORDER BY year DESC, total_sales DESC
LIMIT 100
