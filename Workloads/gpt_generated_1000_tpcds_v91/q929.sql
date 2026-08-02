WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    WHERE cs.cs_quantity >= 2
      AND cs.cs_ext_sales_price > 50
      AND cs.cs_net_paid > 1000
      AND cs.cs_ext_discount_amt < 20
)
SELECT
    w.w_warehouse_name,
    sm.sm_type,
    cd.cd_gender,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    MAX(cs.cs_net_profit) AS max_net_profit,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN warehouse w2 ON cs2.cs_warehouse_sk = w2.w_warehouse_sk
        WHERE w2.w_warehouse_name = w.w_warehouse_name
    ) AS avg_warehouse_profit
FROM filtered_sales cs
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE td.t_second IN (13, 15)
  AND sm.sm_type = 'AIR'
  AND w.w_gmt_offset = -5.00
  AND w.w_zip = '44593'
  AND cd.cd_marital_status = 'S'
  AND hd.hd_vehicle_count >= 2
  AND ib.ib_lower_bound >= 40000
  AND EXISTS (
        SELECT 1 FROM customer c_pref
        WHERE c_pref.c_customer_sk = cs.cs_ship_customer_sk
          AND c_pref.c_preferred_cust_flag = 'Y'
    )
GROUP BY ROLLUP (w.w_warehouse_name, sm.sm_type, cd.cd_gender)
ORDER BY w.w_warehouse_name, sm.sm_type, cd.cd_gender
LIMIT 100
