WITH sales_agg AS (
    SELECT
        i.i_category,
        cd_bill.cd_gender,
        SUM(cs.cs_net_paid)            AS total_net_paid,
        SUM(cs.cs_quantity)            AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN inventory inv ON cs.cs_item_sk = inv.inv_item_sk
    WHERE i.i_current_price > 10
    GROUP BY ROLLUP (i.i_category, cd_bill.cd_gender)
),
web_agg AS (
    SELECT
        i2.i_category,
        cd_bill_ws.cd_gender,
        SUM(ws.ws_net_paid)            AS total_net_paid,
        SUM(ws.ws_quantity)            AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN customer_demographics cd_bill_ws ON ws.ws_bill_cdemo_sk = cd_bill_ws.cd_demo_sk
    JOIN household_demographics hd_bill_ws ON ws.ws_bill_hdemo_sk = hd_bill_ws.hd_demo_sk
    JOIN customer_demographics cd_ship_ws ON ws.ws_ship_cdemo_sk = cd_ship_ws.cd_demo_sk
    JOIN household_demographics hd_ship_ws ON ws.ws_ship_hdemo_sk = hd_ship_ws.hd_demo_sk
    JOIN inventory inv_ws ON ws.ws_item_sk = inv_ws.inv_item_sk
    WHERE i2.i_current_price > 10
    GROUP BY ROLLUP (i2.i_category, cd_bill_ws.cd_gender)
)
SELECT DISTINCT
    category,
    gender,
    total_net_paid,
    total_quantity,
    distinct_orders
FROM (
    SELECT
        i_category AS category,
        cd_gender AS gender,
        total_net_paid,
        total_quantity,
        distinct_orders
    FROM sales_agg
    UNION ALL
    SELECT
        i_category AS category,
        cd_gender AS gender,
        total_net_paid,
        total_quantity,
        distinct_orders
    FROM web_agg
) combined
ORDER BY category, gender, total_net_paid DESC
LIMIT 100
