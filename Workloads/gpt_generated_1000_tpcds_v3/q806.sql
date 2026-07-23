WITH daily_sales AS (
    SELECT d.d_date AS event_date,
           'sales' AS metric_type,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_ext_sales_price) AS total_amount,
           SUM(ws.ws_net_profit) AS total_gain_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-01-31'
      AND sm.sm_carrier = 'MSC'
      AND hd.hd_vehicle_count >= 0
    GROUP BY d.d_date
),

daily_returns AS (
    SELECT d.d_date AS event_date,
           'returns' AS metric_type,
           SUM(wr.wr_return_quantity) AS total_quantity,
           SUM(wr.wr_return_amt) AS total_amount,
           -SUM(wr.wr_net_loss) AS total_gain_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-01-31'
      AND r.r_reason_id = 'AAAAAAAAABAAAAAA'
      AND hd.hd_buy_potential = '0-500'
    GROUP BY d.d_date
)
SELECT event_date,
       metric_type,
       total_quantity,
       total_amount,
       total_gain_loss
FROM daily_sales
UNION ALL
SELECT event_date,
       metric_type,
       total_quantity,
       total_amount,
       total_gain_loss
FROM daily_returns
ORDER BY event_date, metric_type
LIMIT 100
