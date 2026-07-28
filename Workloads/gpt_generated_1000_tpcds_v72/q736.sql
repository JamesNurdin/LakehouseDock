WITH catalog_data AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sales_price > 50
      AND sm.sm_type = 'AIR'
    GROUP BY cd.cd_gender
),
web_data AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sales_price > 50
      AND sm.sm_type = 'AIR'
    GROUP BY cd.cd_gender
)
SELECT gender,
       total_sales,
       distinct_orders
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
) AS combined
ORDER BY gender,
         total_sales DESC
LIMIT 100
