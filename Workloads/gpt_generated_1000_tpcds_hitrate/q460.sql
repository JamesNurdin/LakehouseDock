WITH filtered_sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_bill_hdemo_sk,
    ws.ws_ship_hdemo_sk,
    ws.ws_net_paid_inc_tax,
    ws.ws_coupon_amt,
    ws.ws_quantity,
    ws.ws_ext_discount_amt,
    ws.ws_ext_sales_price,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound
  FROM web_sales ws
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE hd.hd_buy_potential = '>10000'
    AND hd.hd_vehicle_count >= 1
    AND ib.ib_lower_bound >= 50000
    AND ws.ws_coupon_amt > 100.00
    AND ws.ws_net_paid_inc_tax BETWEEN 1000 AND 5000
),

lateral_discount AS (
  SELECT
    fs.*,
    ld.total_discount
  FROM filtered_sales fs
  LEFT JOIN LATERAL (
    SELECT SUM(ws2.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws2
    WHERE ws2.ws_order_number = fs.ws_order_number
  ) ld ON TRUE
),

aggregated AS (
  SELECT
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(ws_net_paid_inc_tax) AS total_net_paid,
    AVG(ws_coupon_amt) AS avg_coupon,
    MIN(ws_ext_sales_price) AS min_sales_price,
    MAX(ws_ext_sales_price) AS max_sales_price,
    SUM(total_discount) AS total_discount_sum
  FROM lateral_discount
  GROUP BY hd_buy_potential, ib_lower_bound, ib_upper_bound
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY hd_buy_potential ORDER BY total_net_paid DESC) AS rn
  FROM aggregated
),

vehicle_demo AS (
  SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count > 0
),
no_vehicle_demo AS (
  SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count = 0
),

demo_excluding AS (
  SELECT hd_demo_sk FROM vehicle_demo
  EXCEPT
  SELECT hd_demo_sk FROM no_vehicle_demo
)
SELECT
  r.hd_buy_potential,
  r.ib_lower_bound,
  r.ib_upper_bound,
  r.order_cnt,
  r.total_net_paid,
  r.avg_coupon,
  r.min_sales_price,
  r.max_sales_price,
  r.total_discount_sum,
  de.hd_demo_sk
FROM ranked r
JOIN demo_excluding de ON de.hd_demo_sk = (
  SELECT MIN(hd_demo_sk)
  FROM household_demographics
  WHERE hd_buy_potential = r.hd_buy_potential
)
WHERE r.rn <= 3
ORDER BY r.hd_buy_potential, r.total_net_paid DESC
LIMIT 100
