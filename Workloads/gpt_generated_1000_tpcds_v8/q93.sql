WITH base AS (
    SELECT
        cc.cc_division,
        cp.cp_department,
        w.w_state,
        wp.wp_max_ad_count,
        td_cs.t_hour AS sale_hour,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS sale_type,
        cr.cr_return_quantity,
        cr.cr_net_loss
    FROM catalog_sales cs
    JOIN time_dim td_cs
      ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer cust_bill
      ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN time_dim td_cr
      ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN inventory inv
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON wp.wp_customer_sk = cust_bill.c_customer_sk
    LEFT JOIN store_sales ss
      ON ss.ss_customer_sk = cust_bill.c_customer_sk
     AND ss.ss_sold_time_sk = td_cs.t_time_sk
    WHERE cc.cc_division IN (1, 2, 3)
      AND wp.wp_max_ad_count >= 2
      AND cp.cp_department = 'Sports'
      AND w.w_state = 'CA'
      AND td_cs.t_hour BETWEEN 8 AND 20
)
SELECT
    cc_division,
    cp_department,
    w_state,
    sale_type,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    AVG(CASE WHEN cr_return_quantity IS NOT NULL THEN cr_return_quantity ELSE 0 END) AS avg_return_qty,
    COUNT(*) AS txn_count,
    (SELECT AVG(cs_ext_sales_price)
       FROM catalog_sales
       WHERE cs_sold_date_sk = 2451921) AS overall_avg_price
FROM base
GROUP BY ROLLUP (cc_division, cp_department, w_state, sale_type)
HAVING SUM(cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
