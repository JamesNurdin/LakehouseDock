WITH bill_sales AS (
        SELECT
            cc.cc_call_center_id,
            ca.ca_city,
            SUM(cs.cs_ext_sales_price) AS total_sales
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        WHERE cc.cc_class = 'large'
          AND ca.ca_location_type = 'apartment'
          AND cs.cs_ext_sales_price > 1000
        GROUP BY cc.cc_call_center_id, ca.ca_city
    ),
    ship_sales AS (
        SELECT
            cc.cc_call_center_id,
            ca.ca_city,
            SUM(cs.cs_ext_sales_price) AS total_sales
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
        WHERE cc.cc_class = 'small'
          AND ca.ca_location_type = 'condo'
          AND cs.cs_ext_sales_price > 500
        GROUP BY cc.cc_call_center_id, ca.ca_city
    ),
    combined AS (
        SELECT * FROM bill_sales
        UNION ALL
        SELECT * FROM ship_sales
    )
SELECT
    c.cc_call_center_id,
    c.ca_city,
    c.total_sales
FROM combined c
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        JOIN call_center cc2 ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
        WHERE cc2.cc_call_center_id = c.cc_call_center_id
          AND cs2.cs_net_profit > 5000
    )
ORDER BY c.total_sales DESC
LIMIT 100
