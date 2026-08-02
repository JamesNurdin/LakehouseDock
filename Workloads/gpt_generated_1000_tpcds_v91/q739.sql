WITH transaction_agg AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price AS sales,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_sold_time_sk,
        cs_bill_hdemo.hd_vehicle_count,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_ext_sales_price DESC) AS rn_item_sales
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim cs_time ON cs.cs_sold_time_sk = cs_time.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion promo_cs ON cs.cs_promo_sk = promo_cs.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer cs_bill_cust ON cs.cs_bill_customer_sk = cs_bill_cust.c_customer_sk
    JOIN household_demographics cs_bill_hdemo ON cs.cs_bill_hdemo_sk = cs_bill_hdemo.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN time_dim cr_time ON cr.cr_returned_time_sk = cr_time.t_time_sk
    LEFT JOIN reason cr_reason ON cr.cr_reason_sk = cr_reason.r_reason_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN time_dim sr_time ON sr.sr_return_time_sk = sr_time.t_time_sk
    LEFT JOIN reason sr_reason ON sr.sr_reason_sk = sr_reason.r_reason_sk
    LEFT JOIN customer sr_cust ON sr.sr_customer_sk = sr_cust.c_customer_sk
    LEFT JOIN household_demographics sr_hdemo ON sr.sr_hdemo_sk = sr_hdemo.hd_demo_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN time_dim ws_time ON ws.ws_sold_time_sk = ws_time.t_time_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN promotion promo_ws ON ws.ws_promo_sk = promo_ws.p_promo_sk
    LEFT JOIN customer ws_bill_cust ON ws.ws_bill_customer_sk = ws_bill_cust.c_customer_sk
    LEFT JOIN household_demographics ws_bill_hdemo ON ws.ws_bill_hdemo_sk = ws_bill_hdemo.hd_demo_sk
    LEFT JOIN ship_mode ws_ship_mode ON ws.ws_ship_mode_sk = ws_ship_mode.sm_ship_mode_sk
    LEFT JOIN warehouse ws_warehouse ON ws.ws_warehouse_sk = ws_warehouse.w_warehouse_sk
    WHERE cs.cs_quantity > 1
      AND cs_bill_hdemo.hd_vehicle_count > 0
      AND ws.ws_sales_price > 20
      AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_customer_sk = cs_bill_cust.c_customer_sk
          AND sr2.sr_return_quantity > 0
      )
),
item_hour_sales AS (
    SELECT 
        i.i_category,
        td.t_hour,
        SUM(ta.sales) AS total_sales,
        COUNT(DISTINCT ta.cs_order_number) AS distinct_orders
    FROM transaction_agg ta
    JOIN item i ON ta.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON ta.cs_sold_time_sk = td.t_time_sk
    GROUP BY ROLLUP (i.i_category, td.t_hour)
)
SELECT 
    i_category,
    t_hour,
    total_sales,
    distinct_orders,
    AVG(total_sales) OVER (PARTITION BY i_category) AS avg_sales_by_category
FROM item_hour_sales
WHERE total_sales > 500
ORDER BY total_sales DESC
LIMIT 100
