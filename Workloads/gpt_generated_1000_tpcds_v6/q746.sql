WITH sales_agg AS (
   SELECT
      w.w_warehouse_id,
      sm.sm_carrier,
      sm.sm_contract,
      td.t_hour,
      hd.hd_vehicle_count,
      SUM(cs.cs_ext_sales_price + ws.ws_ext_sales_price) AS total_sales,
      SUM(cs.cs_ext_discount_amt + ws.ws_ext_discount_amt) AS total_discount,
      COUNT(DISTINCT cs.cs_order_number) AS cnt_orders,
      CASE
         WHEN SUM(cs.cs_ext_sales_price) > (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) THEN 'High'
         ELSE 'Low'
      END AS sales_level
   FROM catalog_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE
      sm.sm_carrier IN ('LATVIAN', 'AIRBORNE')
      AND sm.sm_contract LIKE 'A%'
      AND w.w_warehouse_id IS NOT NULL
      AND cs.cs_ext_sales_price > 1000
      AND hd.hd_vehicle_count >= 2
      AND td.t_hour BETWEEN 9 AND 17
   GROUP BY
      w.w_warehouse_id,
      sm.sm_carrier,
      sm.sm_contract,
      td.t_hour,
      hd.hd_vehicle_count
),
agg_by_wh AS (
   SELECT
      w_warehouse_id,
      sm_carrier,
      AVG(total_sales) AS avg_total_sales,
      SUM(cnt_orders) AS total_orders,
      MAX(sales_level) AS sales_level
   FROM sales_agg
   GROUP BY w_warehouse_id, sm_carrier
   HAVING AVG(total_sales) > 5000
)
SELECT
   w_warehouse_id,
   sm_carrier,
   avg_total_sales,
   total_orders,
   sales_level
FROM agg_by_wh
ORDER BY avg_total_sales DESC
LIMIT 100
