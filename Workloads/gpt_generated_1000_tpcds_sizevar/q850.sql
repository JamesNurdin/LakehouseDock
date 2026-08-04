WITH
  agg_returns AS (
    SELECT
      wr_order_number,
      SUM(wr_return_amt_inc_tax) AS total_return_inc_tax,
      COUNT(*) AS return_cnt
    FROM web_returns
    GROUP BY wr_order_number
  ),
  small_set AS (
    SELECT 1 AS dummy UNION ALL SELECT 2 UNION ALL SELECT 3
  )
SELECT
  ws.ws_order_number,
  ws.ws_sold_date_sk,
  d_sold.d_date                AS sold_date,
  d_ship.d_date                AS ship_date,
  t_sold.t_time                AS sold_time,
  p_active.p_promo_name,
  agg_returns.total_return_inc_tax,
  agg_returns.return_cnt,
  (
    SELECT SUM(wr_return_amt_inc_tax)
    FROM web_returns wr2
    WHERE wr2.wr_order_number = ws.ws_order_number
  )                            AS total_return_amount_scalar,
  LAG(ws.ws_net_paid) OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY ws.ws_sold_date_sk) AS lag_net_paid,
  ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY ws.ws_net_paid DESC)           AS rn
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN promotion p_active
  ON ws.ws_promo_sk = p_active.p_promo_sk
JOIN date_dim d_p_start
  ON p_active.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end
  ON p_active.p_end_date_sk = d_p_end.d_date_sk
JOIN agg_returns
  ON ws.ws_order_number = agg_returns.wr_order_number
LEFT JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
 AND ws.ws_item_sk = wr.wr_item_sk
JOIN date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
  ON wr.wr_returned_time_sk = t_return.t_time_sk
CROSS JOIN small_set
WHERE d_sold.d_year = 1900
  AND t_sold.t_hour BETWEEN 5 AND 10
GROUP BY
  ws.ws_order_number,
  ws.ws_sold_date_sk,
  d_sold.d_date,
  d_ship.d_date,
  t_sold.t_time,
  p_active.p_promo_name,
  agg_returns.total_return_inc_tax,
  agg_returns.return_cnt,
  ws.ws_ship_mode_sk,
  ws.ws_net_paid
HAVING COUNT(DISTINCT wr.wr_reason_sk) > 1
UNION DISTINCT
SELECT DISTINCT
  ws2.ws_order_number,
  ws2.ws_sold_date_sk,
  d2.d_date                AS sold_date,
  d2_2.d_date              AS ship_date,
  t2.t_time                AS sold_time,
  p2.p_promo_name,
  agg2.total_return_inc_tax,
  agg2.return_cnt,
  (
    SELECT SUM(wr_return_amt_inc_tax)
    FROM web_returns wr3
    WHERE wr3.wr_order_number = ws2.ws_order_number
  )                         AS total_return_amount_scalar,
  LAG(ws2.ws_net_paid) OVER (PARTITION BY ws2.ws_ship_mode_sk ORDER BY ws2.ws_sold_date_sk) AS lag_net_paid,
  ROW_NUMBER() OVER (PARTITION BY ws2.ws_ship_mode_sk ORDER BY ws2.ws_net_paid DESC)           AS rn
FROM web_sales ws2
JOIN date_dim d2
  ON ws2.ws_sold_date_sk = d2.d_date_sk
JOIN time_dim t2
  ON ws2.ws_sold_time_sk = t2.t_time_sk
JOIN date_dim d2_2
  ON ws2.ws_ship_date_sk = d2_2.d_date_sk
JOIN promotion p2
  ON ws2.ws_promo_sk = p2.p_promo_sk
JOIN date_dim d2_p_start
  ON p2.p_start_date_sk = d2_p_start.d_date_sk
JOIN date_dim d2_p_end
  ON p2.p_end_date_sk = d2_p_end.d_date_sk
JOIN agg_returns agg2
  ON ws2.ws_order_number = agg2.wr_order_number
WHERE d2.d_year = 1900
  AND t2.t_hour BETWEEN 5 AND 10
ORDER BY ws_sold_date_sk DESC, ws_order_number
OFFSET 0 ROWS
LIMIT 100
