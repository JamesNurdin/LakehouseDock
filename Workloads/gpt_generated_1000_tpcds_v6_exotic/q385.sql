WITH morning_sales AS (
    SELECT
        'Morning' AS period,
        CASE WHEN cs.cs_ext_discount_amt > 1000 THEN 'HIGH' ELSE 'LOW' END AS discount_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM tpcds.catalog_sales cs
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND cc.cc_state = 'CA'
      AND ca.ca_state = 'CA'
    GROUP BY CASE WHEN cs.cs_ext_discount_amt > 1000 THEN 'HIGH' ELSE 'LOW' END
),
afternoon_sales AS (
    SELECT
        'Afternoon' AS period,
        CASE WHEN cs.cs_ext_discount_amt > 500 THEN 'HIGH' ELSE 'LOW' END AS discount_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM tpcds.catalog_sales cs
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 13 AND 17
      AND cc.cc_state = 'NY'
      AND ca.ca_state = 'NY'
    GROUP BY CASE WHEN cs.cs_ext_discount_amt > 500 THEN 'HIGH' ELSE 'LOW' END
)
SELECT *
FROM morning_sales
UNION ALL
SELECT *
FROM afternoon_sales
ORDER BY total_sales DESC
LIMIT 100
