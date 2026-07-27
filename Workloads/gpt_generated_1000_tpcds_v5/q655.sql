WITH cr AS (
    SELECT
        cr_returned_date_sk,
        cr_return_amount,
        cr_return_tax,
        cr_net_loss,
        cr_call_center_sk,
        cr_warehouse_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_hdemo_sk,
        cr_item_sk,
        cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount > 1000
      AND cr_return_quantity > 1
),
sr AS (
    SELECT
        sr_returned_date_sk,
        sr_return_amt,
        sr_return_tax,
        sr_net_loss,
        sr_store_sk,
        sr_cdemo_sk,
        sr_hdemo_sk,
        sr_item_sk,
        sr_ticket_number
    FROM store_returns
    WHERE sr_return_amt > 500
)
SELECT
    cc.cc_name,
    w.w_city,
    s.s_store_name,
    hd.hd_vehicle_count,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    CASE
        WHEN SUM(cr.cr_return_amount) > SUM(sr.sr_return_amt) THEN 'CATALOG_HIGH'
        ELSE 'STORE_HIGH'
    END AS higher_return_source
FROM cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
 AND sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
WHERE cc.cc_gmt_offset = -5.00
  AND w.w_city = 'Pleasant Grove'
  AND hd.hd_vehicle_count >= 2
  AND EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_warehouse_sk = w.w_warehouse_sk
          AND i.inv_quantity_on_hand > 500
    )
GROUP BY cc.cc_name, w.w_city, s.s_store_name, hd.hd_vehicle_count
ORDER BY total_catalog_return_amount DESC
LIMIT 100
