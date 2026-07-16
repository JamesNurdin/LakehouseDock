SELECT sr.sr_return_amt + sr.sr_return_tax AS total_return_amount,
       sr.sr_return_quantity * 2 AS double_quantity,
       CASE WHEN hd.hd_vehicle_count > hd.hd_dep_count THEN 'MoreVehicles' ELSE 'FewerOrEqual' END AS vehicle_status,
       CONCAT(CAST(sr.sr_ticket_number AS VARCHAR), '-', CAST(sr.sr_return_quantity AS VARCHAR)) AS ticket_quantity_concat
FROM store_returns sr
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE sr.sr_returned_date_sk = 2451964
  AND hd.hd_income_band_sk = 1
