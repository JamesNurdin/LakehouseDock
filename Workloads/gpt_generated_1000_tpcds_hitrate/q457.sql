WITH
  -- Billing household rows with filters and correlated existence check
  billing AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_buy_potential,
      hd.hd_vehicle_count,
      CASE
        WHEN ws.ws_net_profit > 0 THEN 'Profitable'
        WHEN ws.ws_net_profit < 0 THEN 'Loss'
        ELSE 'Break-even'
      END AS profit_segment,
      ws.ws_ext_sales_price AS sales_amount
    FROM
      web_sales ws
      INNER JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
      ws.ws_wholesale_cost > 30
      AND hd.hd_vehicle_count >= 0
      AND hd.hd_buy_potential LIKE '%5000%'
      AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = ws.ws_item_sk
          AND ws2.ws_net_profit > 0
      )
  ),
  -- Shipping household rows with a different set of filters and correlated existence check
  shipping AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_buy_potential,
      hd.hd_vehicle_count,
      CASE
        WHEN ws.ws_net_profit > 0 THEN 'Profitable'
        WHEN ws.ws_net_profit < 0 THEN 'Loss'
        ELSE 'Break-even'
      END AS profit_segment,
      ws.ws_ext_sales_price AS sales_amount
    FROM
      web_sales ws
      INNER JOIN household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    WHERE
      ws.ws_wholesale_cost > 40
      AND hd.hd_dep_count >= 5
      AND hd.hd_buy_potential NOT LIKE 'Unknown'
      AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = ws.ws_item_sk
          AND ws2.ws_net_profit > 0
      )
  ),
  -- Union of the two sources
  unified AS (
    SELECT hd_demo_sk, hd_buy_potential, hd_vehicle_count, profit_segment, sales_amount FROM billing
    UNION ALL
    SELECT hd_demo_sk, hd_buy_potential, hd_vehicle_count, profit_segment, sales_amount FROM shipping
  ),
  -- Small static dimension for a cross join
  dim AS (
    SELECT * FROM (VALUES (1, 'Group_A'), (2, 'Group_B')) AS t(dim_id, dim_name)
  ),
  -- Combine dimension with sales rows (cartesian product) and roll‑up aggregates
  aggregated AS (
    SELECT
      dim.dim_name,
      unified.hd_buy_potential,
      unified.hd_vehicle_count,
      SUM(unified.sales_amount) AS total_sales
    FROM unified
    CROSS JOIN dim
    GROUP BY ROLLUP (dim.dim_name, unified.hd_buy_potential, unified.hd_vehicle_count)
  )
SELECT
  dim_name,
  hd_buy_potential,
  hd_vehicle_count,
  total_sales,
  CASE
    WHEN total_sales > 10000 THEN 'High'
    ELSE 'Low'
  END AS sales_category
FROM aggregated
ORDER BY
  dim_name NULLS LAST,
  hd_buy_potential NULLS LAST,
  hd_vehicle_count NULLS LAST
LIMIT 100
