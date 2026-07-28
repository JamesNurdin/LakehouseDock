WITH catalog_agg AS (
    SELECT d.d_year AS year,
           'Catalog' AS channel,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM tpcds.catalog_sales cs
    INNER JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year
),
web_agg AS (
    SELECT d.d_year AS year,
           'Web' AS channel,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM tpcds.web_sales ws
    INNER JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year
)
SELECT year,
       channel,
       total_sales,
       sales_level
FROM catalog_agg
UNION ALL
SELECT year,
       channel,
       total_sales,
       sales_level
FROM web_agg
ORDER BY total_sales DESC
LIMIT 100
