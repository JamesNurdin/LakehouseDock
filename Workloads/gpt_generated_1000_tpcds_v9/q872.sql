WITH bill_hdh AS (
   SELECT
      hd.hd_buy_potential,
      hd.hd_vehicle_count,
      REGEXP_EXTRACT(hd.hd_buy_potential, '^([0-9]+)-([0-9]+)$', 1) AS low_range,
      REGEXP_EXTRACT(hd.hd_buy_potential, '^([0-9]+)-([0-9]+)$', 2) AS high_range,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
      CONCAT(hd.hd_buy_potential, ' #', CAST(hd.hd_vehicle_count AS VARCHAR)) AS concat_desc
   FROM web_sales ws
   JOIN household_demographics hd
     ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_buy_potential LIKE '%-%'
     AND REGEXP_LIKE(hd.hd_buy_potential, '^[0-9]+-[0-9]+$')
     AND hd.hd_vehicle_count >= 1
   GROUP BY GROUPING SETS (
      (hd.hd_buy_potential, hd.hd_vehicle_count),
      (hd.hd_buy_potential),
      ()
   )
), ship_hdh AS (
   SELECT
      hd.hd_buy_potential,
      hd.hd_vehicle_count,
      REGEXP_EXTRACT(hd.hd_buy_potential, '^>([0-9]+)$', 1) AS high_limit,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
      CONCAT('Potential:', hd.hd_buy_potential) AS concat_desc
   FROM web_sales ws
   JOIN household_demographics hd
     ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_buy_potential LIKE '>%'
     AND REGEXP_LIKE(hd.hd_buy_potential, '^>\\d+$')
   GROUP BY CUBE (hd.hd_buy_potential, hd.hd_vehicle_count)
)
SELECT
   role,
   hd_buy_potential,
   hd_vehicle_count,
   total_sales,
   distinct_orders,
   concat_desc,
   low_range,
   high_range,
   high_limit
FROM (
   SELECT
      'Bill' AS role,
      hd_buy_potential,
      hd_vehicle_count,
      total_sales,
      distinct_orders,
      concat_desc,
      low_range,
      high_range,
      CAST(NULL AS VARCHAR) AS high_limit
   FROM bill_hdh
   UNION ALL
   SELECT
      'Ship' AS role,
      hd_buy_potential,
      hd_vehicle_count,
      total_sales,
      distinct_orders,
      concat_desc,
      CAST(NULL AS VARCHAR) AS low_range,
      CAST(NULL AS VARCHAR) AS high_range,
      high_limit
   FROM ship_hdh
) combined
ORDER BY role, hd_buy_potential, hd_vehicle_count
LIMIT 100
