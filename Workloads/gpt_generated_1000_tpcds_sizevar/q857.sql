WITH inv_agg AS (
   SELECT
       inv_item_sk,
       inv_warehouse_sk,
       inv_date_sk,
       SUM(inv_quantity_on_hand) AS total_qty
   FROM inventory TABLESAMPLE BERNOULLI (10)
   GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
),
cp_agg AS (
   SELECT
       cp_catalog_page_sk,
       cp_department,
       cp_start_date_sk,
       COUNT(*) AS page_cnt
   FROM catalog_page
   GROUP BY cp_catalog_page_sk, cp_department, cp_start_date_sk
),
missing_orders AS (
   SELECT ws_order_number
   FROM web_sales
   EXCEPT
   SELECT cr_order_number
   FROM catalog_returns
),
union_cp_reason AS (
   SELECT cp_catalog_page_id AS id FROM catalog_page
   UNION
   SELECT r_reason_id FROM reason
)
SELECT
    d.d_year,
    ib.ib_income_band_sk,
    SUM(CASE WHEN inv.total_qty > 1000 THEN inv.total_qty ELSE 0 END) AS high_qty_sum,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
    AVG(sr.sr_net_loss) AS avg_store_loss,
    SUM(CASE WHEN cr.cr_return_amount > 1500 THEN cr.cr_return_amount ELSE 0 END) AS high_return_amount_sum,
    (SELECT COUNT(*) FROM household_demographics hd_sub WHERE hd_sub.hd_income_band_sk = ib.ib_income_band_sk) AS hd_in_band_cnt,
    CASE
        WHEN COUNT(DISTINCT ws.ws_order_number) > 5000 THEN 'BIG'
        ELSE 'SMALL'
    END AS order_volume_category
FROM inv_agg inv
JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
FULL OUTER JOIN cp_agg cp ON d.d_date_sk = cp.cp_start_date_sk
LEFT JOIN catalog_returns cr ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
LEFT JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
LEFT JOIN income_band ib ON hd_refund.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
LEFT JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
WHERE d.d_year BETWEEN 1998 AND 2000
  AND cp.cp_department = 'Books'
  AND inv.total_qty > 0
  AND cr.cr_return_amount > 200
  AND ws.ws_quantity >= 1
  AND hd_refund.hd_vehicle_count <= 2
  AND EXISTS (SELECT 1 FROM missing_orders mo WHERE mo.ws_order_number = ws.ws_order_number)
GROUP BY d.d_year, ib.ib_income_band_sk
ORDER BY high_qty_sum DESC, d.d_year
LIMIT 100
