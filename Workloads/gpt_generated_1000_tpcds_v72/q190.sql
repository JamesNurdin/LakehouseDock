WITH base AS (
  SELECT
    ws.ws_order_number,
    d_sold.d_year AS sold_year,
    sm.sm_carrier,
    ws.ws_net_profit,
    ws.ws_net_paid,
    ws.ws_quantity,
    ws.ws_bill_cdemo_sk
  FROM web_sales ws
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  WHERE d_sold.d_year BETWEEN 2000 AND 2002
    AND sm.sm_carrier = 'UPS'
    AND cd_bill.cd_education_status = '4 yr Degree'
    AND cd_ship.cd_gender = 'F'
    AND ws.ws_net_paid > 0
    AND ws.ws_quantity >= 1
),
agg AS (
  SELECT
    sold_year,
    sm_carrier,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(ws_net_profit) AS total_net_profit
  FROM base b
  WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN date_dim d_ret
      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE sr.sr_cdemo_sk = b.ws_bill_cdemo_sk
      AND sr.sr_net_loss > 100
      AND d_ret.d_year = b.sold_year
  )
  GROUP BY sold_year, sm_carrier
  HAVING SUM(ws_net_profit) > 0
)
SELECT
  sold_year,
  sm_carrier,
  distinct_orders,
  total_net_profit,
  RANK() OVER (PARTITION BY sold_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY sold_year DESC, profit_rank
LIMIT 100
