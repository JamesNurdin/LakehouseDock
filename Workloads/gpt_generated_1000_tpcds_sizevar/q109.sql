WITH sub1 AS (
    SELECT
        cc.cc_name AS call_center_name,
        w.w_warehouse_name AS warehouse_name,
        cd_bill.cd_gender AS gender,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_current ON c_bill.c_current_cdemo_sk = cd_current.cd_demo_sk
    WHERE cc.cc_country = 'United States'
      AND cd_bill.cd_gender = 'M'
    GROUP BY cc.cc_name, w.w_warehouse_name, cd_bill.cd_gender
),
sub2 AS (
    SELECT
        cc.cc_name AS call_center_name,
        w.w_warehouse_name AS warehouse_name,
        cd_bill.cd_gender AS gender,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_current ON c_bill.c_current_cdemo_sk = cd_current.cd_demo_sk
    WHERE cc.cc_division = 2
      AND cd_bill.cd_gender = 'F'
    GROUP BY cc.cc_name, w.w_warehouse_name, cd_bill.cd_gender
)
SELECT
    call_center_name,
    warehouse_name,
    gender,
    total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY call_center_name ORDER BY total_net_profit DESC) AS row_num
FROM (
    SELECT * FROM sub1
    INTERSECT
    SELECT * FROM sub2
) AS intersected
ORDER BY total_net_profit DESC
LIMIT 100
