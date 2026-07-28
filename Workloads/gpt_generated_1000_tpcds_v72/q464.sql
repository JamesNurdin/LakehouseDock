WITH preferred_sales AS (
    SELECT
        c.c_customer_id,
        sm.sm_type AS ship_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_category
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND sm.sm_type = 'AIR'
      AND cd.cd_purchase_estimate >= 6000
    GROUP BY c.c_customer_id, sm.sm_type, cd.cd_gender
),
non_preferred_sales AS (
    SELECT
        c.c_customer_id,
        sm.sm_type AS ship_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_category
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE c.c_preferred_cust_flag = 'N'
      AND sm.sm_type = 'GROUND'
      AND cd.cd_purchase_estimate < 6000
    GROUP BY c.c_customer_id, sm.sm_type, cd.cd_gender
)
SELECT DISTINCT *
FROM (
    SELECT * FROM preferred_sales
    UNION ALL
    SELECT * FROM non_preferred_sales
) AS combined
ORDER BY total_sales DESC
LIMIT 100
