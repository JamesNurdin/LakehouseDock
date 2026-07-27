WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        pm.p_promo_name,
        sm.sm_type,
        sm.sm_carrier,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        cc.cc_state,
        cp.cp_department,
        ca.ca_state AS cust_state,
        td.t_hour,
        td.t_shift
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion pm ON cs.cs_promo_sk = pm.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE sm.sm_type = 'OVERNIGHT'
      AND sm.sm_carrier = 'UPS'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound <= 50000
      AND cc.cc_state = 'CA'
      AND cd.cd_gender = 'M'
)
SELECT
    b.c_customer_id,
    COUNT(DISTINCT b.cs_order_number) AS order_cnt,
    SUM(b.cs_net_paid) AS total_cs_net_paid,
    AVG(b.cs_ext_sales_price) AS avg_cs_ext_sales_price,
    SUM(ss.ss_net_paid) AS total_ss_net_paid,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(cr.cr_return_amount) AS total_catalog_return_amt,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = b.c_customer_sk) AS total_store_sales_rows,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
FROM base b
LEFT JOIN store_sales ss
    ON ss.ss_customer_sk = b.c_customer_sk
   AND ss.ss_sold_date_sk = b.cs_sold_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = b.c_customer_sk
   AND wr.wr_returned_date_sk = b.cs_sold_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = b.cs_order_number
   AND cr.cr_returned_date_sk = b.cs_sold_date_sk
LEFT JOIN inventory inv
    ON inv.inv_warehouse_sk = b.w_warehouse_sk
WHERE EXISTS (
    SELECT 1 FROM inventory inv2
    WHERE inv2.inv_warehouse_sk = b.w_warehouse_sk
      AND inv2.inv_quantity_on_hand > 0
)
GROUP BY b.c_customer_id, b.c_customer_sk
HAVING COUNT(DISTINCT b.cs_order_number) > 5
ORDER BY total_cs_net_paid DESC
LIMIT 100
