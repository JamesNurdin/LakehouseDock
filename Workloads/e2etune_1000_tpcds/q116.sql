SELECT
    cp.cp_department,
    hd.hd_income_band_sk,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM store_sales ss
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN catalog_page cp
    ON ss.ss_sold_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
WHERE cp.cp_type = 'quarterly'
  AND hd.hd_vehicle_count >= 2
  AND ss.ss_ext_sales_price > 0
GROUP BY cp.cp_department, hd.hd_income_band_sk
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 20
