WITH sales_period1 AS (
        SELECT
            cc.cc_call_center_id,
            cc.cc_name,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            'MKT_ID_3' AS segment
        FROM catalog_sales cs
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE cc.cc_mkt_id = 3
          AND cs.cs_sales_price BETWEEN 30 AND 100
        GROUP BY cc.cc_call_center_id, cc.cc_name
    ),
    sales_period2 AS (
        SELECT
            cc.cc_call_center_id,
            cc.cc_name,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            'MKT_ID_5' AS segment
        FROM catalog_sales cs
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE cc.cc_mkt_id = 5
          AND cs.cs_sales_price > 150
        GROUP BY cc.cc_call_center_id, cc.cc_name
    )
SELECT
    cc_call_center_id,
    cc_name,
    total_sales,
    segment
FROM sales_period1
UNION ALL
SELECT
    cc_call_center_id,
    cc_name,
    total_sales,
    segment
FROM sales_period2
ORDER BY total_sales DESC
LIMIT 100
