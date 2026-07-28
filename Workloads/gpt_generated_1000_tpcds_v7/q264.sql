SELECT warehouse_name,
       segment,
       total_sales,
       orders
FROM (
   SELECT w.w_warehouse_name AS warehouse_name,
          'HighBillPurchase' AS segment,
          SUM(cs.cs_net_paid) AS total_sales,
          COUNT(DISTINCT cs.cs_order_number) AS orders
   FROM tpcds.catalog_sales cs
   JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE cd.cd_purchase_estimate > 7000
     AND hd.hd_income_band_sk >= 10
   GROUP BY w.w_warehouse_name, 'HighBillPurchase'
   UNION ALL
   SELECT w.w_warehouse_name AS warehouse_name,
          'LowShipIncome' AS segment,
          SUM(cs.cs_net_paid) AS total_sales,
          COUNT(DISTINCT cs.cs_order_number) AS orders
   FROM tpcds.catalog_sales cs
   JOIN tpcds.customer_demographics cd_s
        ON cs.cs_ship_cdemo_sk = cd_s.cd_demo_sk
   JOIN tpcds.household_demographics hd_s
        ON cs.cs_ship_hdemo_sk = hd_s.hd_demo_sk
   JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE cd_s.cd_marital_status = 'U'
     AND hd_s.hd_income_band_sk <= 6
   GROUP BY w.w_warehouse_name, 'LowShipIncome'
) AS combined
ORDER BY total_sales DESC
LIMIT 100
