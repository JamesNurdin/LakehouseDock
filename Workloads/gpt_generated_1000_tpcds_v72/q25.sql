WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_quantity
    FROM store_sales ss
    WHERE ss.ss_ext_sales_price > 500
      AND ss.ss_quantity BETWEEN 1 AND 5
      AND ss.ss_store_sk IN (1, 2, 3)
)
SELECT
    td.t_hour,
    hd.hd_income_band_sk,
    sm.sm_carrier,
    COUNT(DISTINCT fs.ss_ticket_number) AS orders,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    AVG(fs.ss_net_paid) AS avg_net_paid,
    MIN(fs.ss_ext_sales_price) AS min_sales,
    MAX(fs.ss_ext_sales_price) AS max_sales,
    SUM(COALESCE(cr.cr_fee, 0)) AS total_return_fees
FROM filtered_sales fs
JOIN time_dim td
  ON fs.ss_sold_time_sk = td.t_time_sk
JOIN household_demographics hd
  ON fs.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_time_sk = td.t_time_sk
  AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE td.t_hour BETWEEN 9 AND 18
  AND hd.hd_income_band_sk IN (3, 7, 12)
  AND hd.hd_vehicle_count >= 1
  AND (sm.sm_carrier = 'UPS' OR sm.sm_carrier = 'FedEx')
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = 30
          AND cr2.cr_returned_date_sk = fs.ss_sold_date_sk
          AND cr2.cr_item_sk = fs.ss_item_sk
    )
GROUP BY td.t_hour, hd.hd_income_band_sk, sm.sm_carrier
ORDER BY total_sales DESC
LIMIT 100
