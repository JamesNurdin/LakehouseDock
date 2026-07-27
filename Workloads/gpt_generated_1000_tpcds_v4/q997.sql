WITH cr AS (
    SELECT cr_order_number, cr_item_sk, cr_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 0
)
SELECT
    cc.cc_call_center_id,
    sm.sm_type,
    cd.cd_education_status,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(cr_sub.cr_return_amount) AS total_returns,
    SUM(ws.ws_net_paid) AS total_web_sales,
    AVG(cs.cs_sales_price) AS avg_sales_price
FROM catalog_sales cs
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN cr cr_sub
    ON cr_sub.cr_order_number = cs.cs_order_number
   AND cr_sub.cr_item_sk = cs.cs_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    cs.cs_sold_date_sk BETWEEN 2450000 AND 2450500
    AND cd.cd_education_status = '4 yr Degree'
    AND i.i_brand = 'Brand1'
    AND sm.sm_type = 'AIR'
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
          AND ws2.ws_net_paid > 5000
    )
GROUP BY
    cc.cc_call_center_id,
    sm.sm_type,
    cd.cd_education_status
HAVING
    SUM(cs.cs_net_paid) > 10000
ORDER BY
    total_catalog_sales DESC
LIMIT 100
