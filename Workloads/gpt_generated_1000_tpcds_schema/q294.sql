WITH
  store_items AS (
    SELECT DISTINCT ss.ss_item_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_class_id IN (1, 8, 14)
      AND ss.ss_ext_list_price > 5000
      AND hd.hd_income_band_sk BETWEEN 10 AND 20
  ),
  web_items AS (
    SELECT DISTINCT ws.ws_item_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_class_id IN (1, 8, 14)
      AND ws.ws_ext_sales_price > 3000
      AND hd.hd_buy_potential <> 'Unknown'
  ),
  common_items AS (
    SELECT ss_item_sk AS i_item_sk FROM store_items
    INTERSECT
    SELECT ws_item_sk FROM web_items
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  SUM(ss.ss_net_paid)                     AS store_net_paid,
  SUM(ws.ws_net_paid)                     AS web_net_paid,
  SUM(cr.cr_net_loss)                     AS total_return_loss,
  (SUM(ss.ss_net_paid) + COALESCE(SUM(ws.ws_net_paid), 0) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_contribution,
  ROW_NUMBER() OVER (ORDER BY (SUM(ss.ss_net_paid) + COALESCE(SUM(ws.ws_net_paid), 0) - COALESCE(SUM(cr.cr_net_loss), 0)) DESC) AS sales_rank
FROM common_items ci
JOIN item i ON ci.i_item_sk = i.i_item_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
WHERE i.i_class_id IN (1, 8, 14)
  AND ss.ss_ext_list_price > 5000
  AND hd_store.hd_income_band_sk BETWEEN 10 AND 20
  AND (hd_refund.hd_vehicle_count IS NULL OR hd_refund.hd_vehicle_count > 1)
  AND i.i_rec_start_date <= DATE '2000-12-31'
  AND i.i_rec_end_date >= DATE '1999-01-01'
GROUP BY i.i_item_id, i.i_product_name
ORDER BY net_contribution DESC
LIMIT 50
