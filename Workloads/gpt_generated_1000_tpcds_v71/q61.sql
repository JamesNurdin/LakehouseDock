WITH joined_sales AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_class,
        cc.cc_tax_percentage,
        sm.sm_ship_mode_id,
        sm.sm_code,
        cd.cd_gender,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_qty,
        COUNT(*) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        cc.cc_class IN ('small', 'medium')
        AND cc.cc_tax_percentage >= 0.01
        AND cc.cc_tax_percentage <= 0.06
        AND sm.sm_code = 'AIR'
        AND cd.cd_gender = 'F'
        AND cs.cs_coupon_amt > 10
        AND cs.cs_sales_price >= 20
        AND cs.cs_quantity BETWEEN 1 AND 10
        AND cs.cs_ship_customer_sk IN (2946785, 6415281)
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_class,
        cc.cc_tax_percentage,
        sm.sm_ship_mode_id,
        sm.sm_code,
        cd.cd_gender
)
SELECT
    js.cc_call_center_id,
    js.cc_class,
    js.cc_tax_percentage,
    js.sm_ship_mode_id,
    js.sm_code,
    js.cd_gender,
    js.total_profit,
    js.total_sales,
    js.total_qty,
    js.order_cnt,
    AVG(js.total_profit) OVER (PARTITION BY js.cc_call_center_id) AS avg_profit_per_cc,
    RANK() OVER (ORDER BY js.total_profit DESC) AS profit_rank
FROM joined_sales js
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.catalog_sales cs2
    JOIN tpcds.call_center cc2
        ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
    WHERE cc2.cc_call_center_id = js.cc_call_center_id
      AND cs2.cs_coupon_amt = 0
)
ORDER BY js.total_profit DESC, js.cc_call_center_id
LIMIT 100
