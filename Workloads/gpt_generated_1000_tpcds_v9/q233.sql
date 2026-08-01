WITH cs_aggregated AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS line_items,
        MAX(cs.cs_net_paid_inc_tax) AS max_paid_inc_tax
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_sales_price > 100
    GROUP BY cs.cs_order_number,
             cs.cs_bill_customer_sk,
             cs.cs_ship_customer_sk,
             cs.cs_call_center_sk,
             cs.cs_catalog_page_sk,
             cs.cs_ship_mode_sk,
             cs.cs_warehouse_sk
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_education_status,
    cc.cc_name,
    cp.cp_type,
    sm.sm_type,
    w.w_city,
    cs_aggregated.total_sales,
    cs_aggregated.total_profit,
    RANK() OVER (PARTITION BY w.w_state ORDER BY cs_aggregated.total_profit DESC) AS profit_state_rank,
    CASE 
        WHEN cs_aggregated.total_sales > 10000 THEN 'HIGH'
        WHEN cs_aggregated.total_sales BETWEEN 5000 AND 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_bracket,
    (SELECT COUNT(*) FROM store_returns sr_inner WHERE sr_inner.sr_customer_sk = c.c_customer_sk) AS sr_cnt,
    EXISTS (SELECT 1 FROM web_returns wr_inner WHERE wr_inner.wr_returning_customer_sk = c.c_customer_sk AND wr_inner.wr_return_amt > 500) AS has_large_web_return
FROM cs_aggregated
JOIN customer c
    ON cs_aggregated.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN call_center cc
    ON cs_aggregated.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs_aggregated.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs_aggregated.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs_aggregated.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
   AND sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs_aggregated.cs_order_number
   AND cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN web_returns wr
    ON wr.wr_returning_customer_sk = c.c_customer_sk
   AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
WHERE cc.cc_country = 'United States'
  AND cp.cp_type = 'DVD'
  AND cd.cd_gender = 'M'
  AND w.w_county = 'Bronx County'
  AND cc.cc_gmt_offset > -5.00
  AND sm.sm_carrier = 'UPS'
ORDER BY cs_aggregated.total_profit DESC, profit_state_rank
LIMIT 100
