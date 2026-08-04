WITH
  sales_bill AS (
    SELECT
      cs.cs_order_number               AS order_number,
      cs.cs_net_paid,
      cs.cs_ext_ship_cost,
      cs.cs_ship_date_sk,
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      hd.hd_dep_count,
      CASE WHEN hd.hd_vehicle_count > 0 THEN 'HasVehicle' ELSE 'NoVehicle' END AS vehicle_flag
    FROM catalog_sales cs
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450865 AND 2450900
      AND cs.cs_ext_ship_cost > 100
      AND hd.hd_income_band_sk IN (12,15,20,17)
      AND hd.hd_dep_count >= 4
  ),
  sales_ship AS (
    SELECT
      cs.cs_order_number               AS order_number,
      cs.cs_net_paid,
      cs.cs_ext_ship_cost,
      cs.cs_ship_date_sk,
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      hd.hd_dep_count,
      CASE WHEN hd.hd_vehicle_count > 0 THEN 'HasVehicle' ELSE 'NoVehicle' END AS vehicle_flag
    FROM catalog_sales cs
    JOIN household_demographics hd
      ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450865 AND 2450900
      AND cs.cs_ext_ship_cost > 100
      AND hd.hd_income_band_sk IN (12,15,20,17)
      AND hd.hd_dep_count >= 4
  ),
  intersect_orders AS (
    SELECT order_number FROM sales_bill
    INTERSECT
    SELECT order_number FROM sales_ship
  ),
  except_orders AS (
    SELECT order_number FROM sales_bill
    EXCEPT
    SELECT order_number FROM sales_ship
  ),
  combined AS (
    SELECT
      sb.order_number,
      sb.cs_net_paid,
      sb.cs_ext_ship_cost,
      sb.cs_ship_date_sk,
      sb.hd_income_band_sk,
      sb.hd_vehicle_count,
      sb.hd_dep_count,
      sb.vehicle_flag,
      l.adj_ship_cost,
      ROW_NUMBER() OVER (PARTITION BY sb.hd_income_band_sk ORDER BY sb.cs_net_paid DESC) AS rn
    FROM sales_bill sb
    CROSS JOIN LATERAL (
      SELECT sb.cs_ext_ship_cost * 0.9 AS adj_ship_cost
    ) AS l
    WHERE sb.order_number IN (SELECT order_number FROM intersect_orders)
  )
SELECT
  hd_income_band_sk,
  hd_vehicle_count,
  hd_dep_count,
  vehicle_flag,
  COUNT(DISTINCT order_number)       AS orders_cnt,
  SUM(cs_net_paid)                  AS total_net_paid,
  AVG(adj_ship_cost)                AS avg_adj_ship_cost,
  MAX(rn)                           AS max_rank
FROM combined
GROUP BY CUBE (hd_income_band_sk, hd_vehicle_count, hd_dep_count, vehicle_flag)
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
