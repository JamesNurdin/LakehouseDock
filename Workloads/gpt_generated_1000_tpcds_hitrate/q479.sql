WITH base1 AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cc.cc_name,
        cd_bill.cd_gender,
        cd_ship.cd_marital_status,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_quantity AS ws_quantity,
        web.web_state,
        web.web_zip
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_demographics cd_extra1
        ON cs.cs_bill_cdemo_sk = cd_extra1.cd_demo_sk
    JOIN customer_demographics cd_extra2
        ON cs.cs_ship_cdemo_sk = cd_extra2.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ws_bill2
        ON ws.ws_bill_cdemo_sk = cd_ws_bill2.cd_demo_sk
    JOIN customer_demographics cd_ws_ship2
        ON ws.ws_ship_cdemo_sk = cd_ws_ship2.cd_demo_sk
    FULL OUTER JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    WHERE cs.cs_wholesale_cost > (
            SELECT MAX(cs2.cs_wholesale_cost)
            FROM catalog_sales cs2
            WHERE cs2.cs_warehouse_sk = 1
        )
      AND EXISTS (
            SELECT 1
            FROM catalog_sales cs3
            WHERE cs3.cs_order_number = cs.cs_order_number
              AND cs3.cs_quantity > 5
        )
),
base2 AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cc.cc_name,
        cd_bill.cd_gender,
        cd_ship.cd_marital_status,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_quantity AS ws_quantity,
        web.web_state,
        web.web_zip
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_demographics cd_extra1
        ON cs.cs_bill_cdemo_sk = cd_extra1.cd_demo_sk
    JOIN customer_demographics cd_extra2
        ON cs.cs_ship_cdemo_sk = cd_extra2.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ws_bill2
        ON ws.ws_bill_cdemo_sk = cd_ws_bill2.cd_demo_sk
    JOIN customer_demographics cd_ws_ship2
        ON ws.ws_ship_cdemo_sk = cd_ws_ship2.cd_demo_sk
    FULL OUTER JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    WHERE cs.cs_wholesale_cost <= (
            SELECT MIN(cs2.cs_wholesale_cost)
            FROM catalog_sales cs2
            WHERE cs2.cs_warehouse_sk = 2
        )
      AND cs.cs_quantity IN (
            SELECT DISTINCT cs3.cs_quantity
            FROM catalog_sales cs3
            WHERE cs3.cs_quantity BETWEEN 1 AND 3
        )
)
SELECT
    order_number,
    total_net_paid,
    total_quantity,
    CASE WHEN total_net_paid > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS revenue_category,
    state,
    zip
FROM (
    SELECT
        cs_order_number AS order_number,
        SUM(cs_net_paid) + SUM(ws_net_paid) AS total_net_paid,
        SUM(cs_quantity) + SUM(ws_quantity) AS total_quantity,
        web_state AS state,
        web_zip AS zip
    FROM base1
    GROUP BY cs_order_number, web_state, web_zip
    UNION DISTINCT
    SELECT
        cs_order_number AS order_number,
        SUM(cs_net_paid) + SUM(ws_net_paid) AS total_net_paid,
        SUM(cs_quantity) + SUM(ws_quantity) AS total_quantity,
        web_state AS state,
        web_zip AS zip
    FROM base2
    GROUP BY cs_order_number, web_state, web_zip
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
