WITH base AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_ship_date_sk,
    ws.ws_warehouse_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    w.w_warehouse_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_dow,
    d_ret.d_week_seq
  FROM web_sales ws
  JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
  WHERE d_sold.d_year = 2001
    AND d_sold.d_month_seq BETWEEN 1 AND 12
    AND w.w_country = 'United States'
    AND ws.ws_quantity > 1
    AND ws.ws_net_profit > 0
    AND wr.wr_return_quantity > 0
    AND d_sold.d_dow IN (1, 3)
    AND d_ret.d_week_seq = 14
),
agg AS (
  SELECT
    b.w_warehouse_name,
    b.d_year,
    b.d_month_seq,
    b.d_week_seq,
    COUNT(DISTINCT b.ws_order_number) AS orders_cnt,
    SUM(b.ws_net_profit) AS total_profit,
    SUM(b.wr_return_amt) AS total_return_amount,
    AVG(b.ws_quantity) AS avg_quantity,
    (
      SELECT AVG(wr2.wr_return_amt)
      FROM web_returns wr2
      JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
      WHERE d2.d_week_seq = b.d_week_seq
    ) AS avg_return_amt_same_week
  FROM base b
  GROUP BY b.w_warehouse_name, b.d_year, b.d_month_seq, b.d_week_seq
  HAVING SUM(b.ws_net_profit) > 10000
)
SELECT
  a.w_warehouse_name,
  a.d_year,
  a.d_month_seq,
  a.orders_cnt,
  a.total_profit,
  a.total_return_amount,
  a.avg_quantity,
  a.avg_return_amt_same_week,
  RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank_by_year
FROM agg a
ORDER BY a.d_year, profit_rank_by_year
LIMIT 100
