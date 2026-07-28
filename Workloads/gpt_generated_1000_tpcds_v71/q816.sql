WITH sales_union AS (
    SELECT
        ca.ca_state AS state,
        concat(ca.ca_state, '-', substr(ca.ca_zip, 1, 2)) AS region,
        sum(cs.cs_ext_sales_price) AS total_sales,
        sum(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(ca.ca_suite_number, '^Suite [A-Z]')
      AND ca.ca_city LIKE '%York%'
      AND sm.sm_code LIKE 'AIR%'
    GROUP BY ca.ca_state, ca.ca_zip
    UNION ALL
    SELECT
        ca.ca_state AS state,
        concat(ca.ca_state, '-', substr(ca.ca_zip, 1, 2)) AS region,
        sum(ws.ws_ext_sales_price) AS total_sales,
        sum(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(ca.ca_suite_number, '^Suite [0-9]+')
      AND ca.ca_city LIKE '%York%'
      AND sm.sm_code LIKE 'AIR%'
    GROUP BY ca.ca_state, ca.ca_zip
)
SELECT su.state,
       su.region,
       su.total_sales,
       su.total_quantity
FROM sales_union su
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
    WHERE ca_ret.ca_state = su.state
)
ORDER BY su.total_sales DESC
LIMIT 100
