WITH recent_return_customers AS (
    SELECT DISTINCT sr.sr_customer_sk
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 17
)
SELECT
    category,
    sale_date_sk,
    total_sales,
    sales_level,
    source,
    total_returns_global
FROM (
    SELECT
        i.i_category AS category,
        cs.cs_sold_date_sk AS sale_date_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_level,
        'catalog' AS source,
        (SELECT SUM(sr_return_amt) FROM store_returns) AS total_returns_global
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE i.i_manufact_id = 86
      AND EXISTS (
          SELECT 1
          FROM recent_return_customers r
          WHERE r.sr_customer_sk = c.c_customer_sk
      )
    GROUP BY i.i_category, cs.cs_sold_date_sk

    UNION ALL

    SELECT
        i.i_category AS category,
        ws.ws_sold_date_sk AS sale_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_level,
        'web' AS source,
        (SELECT SUM(sr_return_amt) FROM store_returns) AS total_returns_global
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE i.i_manufact_id = 86
      AND EXISTS (
          SELECT 1
          FROM recent_return_customers r
          WHERE r.sr_customer_sk = c.c_customer_sk
      )
    GROUP BY i.i_category, ws.ws_sold_date_sk
) AS combined
ORDER BY category, sale_date_sk, source
LIMIT 100
