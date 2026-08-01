WITH
  bill_sales AS (
    SELECT
      ws.ws_bill_hdemo_sk AS hd_demo_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS order_cnt,
      AVG(ws.ws_quantity) AS avg_qty,
      MAX(ws.ws_wholesale_cost) AS max_wholesale_cost,
      REGEXP_EXTRACT(hd.hd_buy_potential, '(\\d+)-(\\d+)', 1) AS lower_range,
      REGEXP_EXTRACT(hd.hd_buy_potential, '(\\d+)-(\\d+)', 2) AS upper_range
    FROM
      web_sales ws
      JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
      REGEXP_LIKE(hd.hd_buy_potential, '\\d+-\\d+')
      AND hd.hd_buy_potential LIKE '%-%'
    GROUP BY
      ws.ws_bill_hdemo_sk,
      hd.hd_buy_potential
  ),
  ship_sales AS (
    SELECT
      ws.ws_ship_hdemo_sk AS hd_demo_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS order_cnt,
      AVG(ws.ws_quantity) AS avg_qty,
      MIN(ws.ws_wholesale_cost) AS min_wholesale_cost,
      REGEXP_EXTRACT(hd.hd_buy_potential, '(\\d+)-(\\d+)', 1) AS lower_range,
      REGEXP_EXTRACT(hd.hd_buy_potential, '(\\d+)-(\\d+)', 2) AS upper_range
    FROM
      web_sales ws
      JOIN household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    WHERE
      REGEXP_LIKE(hd.hd_buy_potential, '\\d+-\\d+')
    GROUP BY
      ws.ws_ship_hdemo_sk,
      hd.hd_buy_potential
  ),
  intersect_keys AS (
    SELECT hd_demo_sk FROM bill_sales
    INTERSECT
    SELECT hd_demo_sk FROM ship_sales
  ),
  full_joined AS (
    SELECT
      COALESCE(b.hd_demo_sk, s.hd_demo_sk) AS hd_demo_sk,
      b.total_sales AS bill_total_sales,
      s.total_sales AS ship_total_sales,
      b.order_cnt AS bill_order_cnt,
      s.order_cnt AS ship_order_cnt,
      CASE
        WHEN b.lower_range IS NOT NULL THEN CONCAT('BP_', b.lower_range, '_', b.upper_range)
        WHEN s.lower_range IS NOT NULL THEN CONCAT('BP_', s.lower_range, '_', s.upper_range)
        ELSE NULL
      END AS buy_potential_code
    FROM
      bill_sales b
      FULL OUTER JOIN ship_sales s
        ON b.hd_demo_sk = s.hd_demo_sk
  )
SELECT
  fj.hd_demo_sk,
  fj.bill_total_sales,
  fj.ship_total_sales,
  fj.bill_order_cnt,
  fj.ship_order_cnt,
  fj.buy_potential_code,
  lat.hd_key_str
FROM
  full_joined fj
  LEFT JOIN LATERAL (
    SELECT CONCAT('HD_', CAST(fj.hd_demo_sk AS VARCHAR)) AS hd_key_str
  ) AS lat ON true
WHERE
  fj.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_keys)
  AND fj.hd_demo_sk NOT IN (
    SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count < 0
  )
ORDER BY
  fj.bill_total_sales DESC,
  fj.ship_total_sales DESC
LIMIT 100
