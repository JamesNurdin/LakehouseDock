WITH
  sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  agg_ws AS (
    SELECT
      ws_bill_hdemo_sk,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_net_profit)       AS total_profit,
      COUNT(*)                 AS sales_cnt
    FROM sampled_ws
    WHERE ws_quantity > 1
      AND ws_ext_sales_price > 100
      AND ws_wholesale_cost < 500
      AND ws_net_paid_inc_ship_tax > 0
      AND ws_ext_discount_amt BETWEEN 0 AND 100
      AND ws_ship_mode_sk IS NOT NULL
    GROUP BY ws_bill_hdemo_sk
  ),
  full_hd_ib AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM household_demographics hd
    FULL OUTER JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  order_intersect AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 5
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_net_profit > 0
  ),
  order_exclusive AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 5
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_net_profit > 0
  )
SELECT
  f.hd_demo_sk,
  f.hd_buy_potential,
  f.ib_lower_bound,
  f.ib_upper_bound,
  a.total_sales,
  a.total_profit,
  CASE
    WHEN a.total_profit > 10000 THEN 'High'
    WHEN a.total_profit > 1000  THEN 'Medium'
    ELSE 'Low'
  END AS profit_category,
  (
    SELECT SUM(ws2.ws_ext_sales_price)
    FROM web_sales ws2
    WHERE ws2.ws_bill_hdemo_sk = f.hd_demo_sk
  ) AS lifetime_sales,
  ws_detail.ws_order_number,
  ws_detail.ws_quantity,
  ws_detail.ws_net_profit
FROM full_hd_ib f
INNER JOIN agg_ws a
  ON f.hd_demo_sk = a.ws_bill_hdemo_sk
INNER JOIN web_sales ws_detail
  ON ws_detail.ws_bill_hdemo_sk = f.hd_demo_sk
WHERE EXISTS (
        SELECT 1
        FROM web_sales ws_check
        WHERE ws_check.ws_ship_hdemo_sk = f.hd_demo_sk
          AND ws_check.ws_quantity > 10
      )
  AND ws_detail.ws_order_number IN (SELECT ws_order_number FROM order_intersect)
  AND ws_detail.ws_order_number NOT IN (SELECT ws_order_number FROM order_exclusive)
  AND f.hd_dep_count BETWEEN 1 AND 7
  AND f.hd_vehicle_count >= 0
  AND f.ib_lower_bound >= 40000
  AND ws_detail.ws_ext_sales_price > 200
  AND ws_detail.ws_net_profit IS NOT NULL
ORDER BY a.total_profit DESC
LIMIT 100
