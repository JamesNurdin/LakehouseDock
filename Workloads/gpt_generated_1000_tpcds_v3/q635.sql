SELECT income_band, total_sales, source
FROM (
   SELECT hd.hd_income_band_sk AS income_band,
          sum(ws.ws_ext_sales_price) AS total_sales,
          'bill' AS source
   FROM web_sales ws
   JOIN household_demographics hd
     ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE ws.ws_ext_tax > 100
     AND hd.hd_vehicle_count >= 2
   GROUP BY hd.hd_income_band_sk
   HAVING sum(ws.ws_ext_sales_price) > (
          SELECT avg(ws2.ws_ext_sales_price)
          FROM web_sales ws2
          WHERE ws2.ws_promo_sk = 952
   )
   UNION ALL
   SELECT hd.hd_income_band_sk AS income_band,
          sum(ws.ws_ext_sales_price) AS total_sales,
          'ship' AS source
   FROM web_sales ws
   JOIN household_demographics hd
     ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
   WHERE ws.ws_ext_tax > 50
     AND hd.hd_dep_count <= 2
   GROUP BY hd.hd_income_band_sk
   HAVING sum(ws.ws_ext_sales_price) > (
          SELECT avg(ws2.ws_ext_sales_price)
          FROM web_sales ws2
          WHERE ws2.ws_promo_sk = 952
   )
) AS combined
ORDER BY total_sales DESC, source
LIMIT 100
