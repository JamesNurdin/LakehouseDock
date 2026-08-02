WITH distinct_items AS (
    SELECT DISTINCT ss_item_sk
    FROM store_sales
    WHERE ss_quantity > 0
)
SELECT
    cc.cc_name,
    cc.cc_class,
    cc.cc_county,
    w_ret.w_warehouse_name AS return_warehouse,
    w_ws.w_warehouse_name AS web_warehouse,
    sm_ret.sm_type AS return_ship_type,
    sm_ws.sm_type AS web_ship_type,
    cd_refunded.cd_gender AS refunded_gender,
    cd_returning.cd_gender AS returning_gender,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    s.s_store_name,
    cd_ss.cd_gender AS store_cust_gender,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(ws.ws_net_paid_inc_ship) AS total_web_net_paid,
    COUNT(DISTINCT ss.ss_item_sk) AS store_sales_distinct_items,
    COUNT(DISTINCT di.ss_item_sk) AS distinct_items_from_cte
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_ret
    ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN warehouse w_ret
    ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
CROSS JOIN web_sales ws
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
CROSS JOIN store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN distinct_items di
    ON ss.ss_item_sk = di.ss_item_sk
WHERE cc.cc_gmt_offset > (
    SELECT AVG(cc2.cc_gmt_offset)
    FROM call_center cc2
)
GROUP BY
    cc.cc_name,
    cc.cc_class,
    cc.cc_county,
    w_ret.w_warehouse_name,
    w_ws.w_warehouse_name,
    sm_ret.sm_type,
    sm_ws.sm_type,
    cd_refunded.cd_gender,
    cd_returning.cd_gender,
    cd_bill.cd_gender,
    cd_ship.cd_gender,
    s.s_store_name,
    cd_ss.cd_gender
HAVING SUM(cr.cr_net_loss) > (
    SELECT AVG(cr3.cr_net_loss)
    FROM catalog_returns cr3
)
ORDER BY total_web_net_paid DESC
LIMIT 100
