WITH
  sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_ship_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_bill_cdemo_sk,
      ws.ws_ship_cdemo_sk,
      ws.ws_web_page_sk,
      ws.ws_ship_mode_sk,
      ws.ws_ext_sales_price,
      ws.ws_net_profit
    FROM web_sales ws
  ),
  date_sold AS (
    SELECT d_date_sk, d_date, d_year FROM date_dim
  ),
  date_ship AS (
    SELECT d_date_sk, d_date FROM date_dim
  ),
  date_close AS (
    SELECT d_date_sk, d_date FROM date_dim
  ),
  date_open AS (
    SELECT d_date_sk, d_date FROM date_dim
  ),
  time_sold AS (
    SELECT t_time_sk, t_hour FROM time_dim
  ),
  cd_bill AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status FROM customer_demographics
  ),
  cd_ship AS (
    SELECT cd_demo_sk, cd_credit_rating FROM customer_demographics
  ),
  wp AS (
    SELECT wp_web_page_sk, wp_url, wp_autogen_flag FROM web_page
  ),
  sm AS (
    SELECT sm_ship_mode_sk, sm_carrier FROM ship_mode
  ),
  cc AS (
    SELECT cc_call_center_id, cc_name, cc_closed_date_sk, cc_open_date_sk FROM call_center
  ),
  returns AS (
    SELECT wr_order_number, wr_return_amt, wr_net_loss FROM web_returns
  )

-- First result set (orders without loss‑making returns)
SELECT * FROM (
  SELECT
    s.ws_order_number,
    ds.d_date               AS sold_date,
    dsh.d_date              AS ship_date,
    cc.cc_name              AS call_center_name,
    wp.wp_url,
    sm.sm_carrier,
    SUM(s.ws_ext_sales_price)   AS total_sales,
    SUM(s.ws_net_profit)        AS total_profit,
    LAG(SUM(s.ws_net_profit)) OVER (PARTITION BY ds.d_year ORDER BY ds.d_date) AS prior_day_profit,
    COALESCE(lr.latest_return_amt, 0) AS latest_return_amount
  FROM sales s
  JOIN date_sold ds   ON s.ws_sold_date_sk = ds.d_date_sk                                 -- join 1
  JOIN date_ship dsh  ON s.ws_ship_date_sk = dsh.d_date_sk                                 -- join 2
  JOIN cc            ON 1=1                                                            -- join 3 (cross for later filters)
  JOIN date_close dc ON cc.cc_closed_date_sk = dc.d_date_sk                               -- join 4
  JOIN date_open do  ON cc.cc_open_date_sk   = do.d_date_sk                               -- join 5
  JOIN time_sold ts   ON s.ws_sold_time_sk = ts.t_time_sk                               -- join 6
  JOIN cd_bill cb    ON s.ws_bill_cdemo_sk = cb.cd_demo_sk                               -- join 7
  JOIN cd_ship cs    ON s.ws_ship_cdemo_sk = cs.cd_demo_sk                               -- join 8
  JOIN wp           ON s.ws_web_page_sk = wp.wp_web_page_sk                             -- join 9
  JOIN sm           ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk                             -- join 10
  LEFT JOIN LATERAL (
    SELECT MAX(r.wr_return_amt) AS latest_return_amt
    FROM returns r
    WHERE r.wr_order_number = s.ws_order_number
  ) lr ON TRUE
  WHERE ds.d_date BETWEEN do.d_date AND dc.d_date                                         -- date range filter
    AND NOT EXISTS (
      SELECT 1 FROM returns r2
      WHERE r2.wr_order_number = s.ws_order_number
        AND r2.wr_net_loss > 0
    )
  GROUP BY
    s.ws_order_number,
    ds.d_date,
    dsh.d_date,
    cc.cc_name,
    wp.wp_url,
    sm.sm_carrier,
    lr.latest_return_amt,
    ds.d_year
) q1

-- Subtract orders that have any return (regardless of loss) using EXCEPT
EXCEPT

SELECT * FROM (
  SELECT
    s.ws_order_number,
    ds.d_date               AS sold_date,
    dsh.d_date              AS ship_date,
    cc.cc_name              AS call_center_name,
    wp.wp_url,
    sm.sm_carrier,
    SUM(s.ws_ext_sales_price)   AS total_sales,
    SUM(s.ws_net_profit)        AS total_profit,
    LAG(SUM(s.ws_net_profit)) OVER (PARTITION BY ds.d_year ORDER BY ds.d_date) AS prior_day_profit,
    COALESCE(lr.latest_return_amt, 0) AS latest_return_amount
  FROM sales s
  JOIN date_sold ds   ON s.ws_sold_date_sk = ds.d_date_sk                                 -- join 1
  JOIN date_ship dsh  ON s.ws_ship_date_sk = dsh.d_date_sk                                 -- join 2
  JOIN cc            ON 1=1                                                            -- join 3
  JOIN date_close dc ON cc.cc_closed_date_sk = dc.d_date_sk                               -- join 4
  JOIN date_open do  ON cc.cc_open_date_sk   = do.d_date_sk                               -- join 5
  JOIN time_sold ts   ON s.ws_sold_time_sk = ts.t_time_sk                               -- join 6
  JOIN cd_bill cb    ON s.ws_bill_cdemo_sk = cb.cd_demo_sk                               -- join 7
  JOIN cd_ship cs    ON s.ws_ship_cdemo_sk = cs.cd_demo_sk                               -- join 8
  JOIN wp           ON s.ws_web_page_sk = wp.wp_web_page_sk                             -- join 9
  JOIN sm           ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk                             -- join 10
  LEFT JOIN LATERAL (
    SELECT MAX(r.wr_return_amt) AS latest_return_amt
    FROM returns r
    WHERE r.wr_order_number = s.ws_order_number
  ) lr ON TRUE
  WHERE ds.d_date BETWEEN do.d_date AND dc.d_date                                         -- date range filter
    AND EXISTS (
      SELECT 1 FROM returns r3
      WHERE r3.wr_order_number = s.ws_order_number
    )
  GROUP BY
    s.ws_order_number,
    ds.d_date,
    dsh.d_date,
    cc.cc_name,
    wp.wp_url,
    sm.sm_carrier,
    lr.latest_return_amt,
    ds.d_year
) q2

ORDER BY total_sales DESC
LIMIT 100
