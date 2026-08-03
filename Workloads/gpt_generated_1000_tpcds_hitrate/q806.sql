WITH catalog_agg AS (
    SELECT 
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 5000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 12
    GROUP BY GROUPING SETS ( 
        (cs.cs_sold_date_sk, cs.cs_bill_customer_sk),
        (cs.cs_sold_date_sk)
    )
),
web_agg AS (
    SELECT 
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 5000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 12
    GROUP BY GROUPING SETS ( 
        (ws.ws_sold_date_sk, ws.ws_bill_customer_sk),
        (ws.ws_sold_date_sk)
    )
)
SELECT 
    ca.date_sk,
    ca.customer_sk,
    ca.total_sales,
    ca.sales_category
FROM catalog_agg ca
WHERE ca.customer_sk IS NOT NULL
INTERSECT
SELECT 
    wa.date_sk,
    wa.customer_sk,
    wa.total_sales,
    wa.sales_category
FROM web_agg wa
WHERE wa.customer_sk IS NOT NULL
ORDER BY total_sales DESC
LIMIT 100
