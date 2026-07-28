WITH base AS (
   SELECT
      cr.cr_return_amount,
      cr.cr_return_tax,
      cr.cr_return_quantity,
      cp.cp_department,
      cp.cp_catalog_number,
      sm.sm_type,
      w.w_warehouse_id,
      w.w_city,
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      ws.ws_ext_wholesale_cost,
      ws.ws_ext_list_price,
      ws.ws_quantity,
      CASE WHEN cr.cr_return_amount > 0 THEN 'Profit' ELSE 'Loss' END AS return_category
   FROM catalog_returns cr
   JOIN catalog_page cp               ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN ship_mode sm              ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w                   ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN web_sales ws                  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cr.cr_return_tax > 20
     AND ws.ws_ext_wholesale_cost > 1000
     AND w.w_gmt_offset = -6.00
     AND cp.cp_department = 'Sports'
     AND hd.hd_vehicle_count >= 1
)
SELECT
   b.w_warehouse_id,
   b.cp_department,
   b.return_category,
   SUM(b.cr_return_amount) OVER (
       PARTITION BY b.w_warehouse_id
       ORDER BY b.cr_return_amount DESC
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   ) AS cumulative_return_amount,
   ROW_NUMBER() OVER (
       PARTITION BY b.w_warehouse_id
       ORDER BY b.cr_return_amount DESC
   ) AS rn,
   COUNT(*) OVER (PARTITION BY b.w_warehouse_id) AS returns_per_warehouse
FROM base b
ORDER BY b.w_warehouse_id, rn
LIMIT 100
