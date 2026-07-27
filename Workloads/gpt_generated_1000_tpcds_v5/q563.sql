WITH joined AS (
  SELECT DISTINCT
    s.s_store_id,
    i.i_brand,
    td.t_hour,
    c.c_customer_id,
    sr.sr_return_amt,
    sr.sr_fee,
    ws.ws_ext_sales_price,
    ws.ws_quantity,
    ws.ws_net_profit,
    wr.wr_return_amt
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  WHERE s.s_hours = '8AM-4PM'
    AND i.i_brand = 'Brand#12'
    AND i.i_color = 'Red'
    AND td.t_hour BETWEEN 8 AND 12
    AND sr.sr_fee > 10
    AND ws.ws_quantity > 2
    AND (wr.wr_return_amt IS NULL OR wr.wr_return_amt > 5)
),
aggregated AS (
  SELECT
    s_store_id,
    i_brand,
    t_hour,
    c_customer_id,
    sr_return_amt,
    ws_ext_sales_price,
    ws_net_profit,
    wr_return_amt
  FROM joined
)
SELECT
  s_store_id,
  i_brand,
  t_hour,
  COUNT(DISTINCT c_customer_id) AS distinct_customers,
  SUM(sr_return_amt) AS total_store_return_amt,
  SUM(ws_ext_sales_price) AS total_sales_price,
  AVG(ws_net_profit) AS avg_net_profit,
  SUM(COALESCE(wr_return_amt, 0)) AS total_web_return_amt
FROM aggregated
GROUP BY s_store_id, i_brand, t_hour
HAVING COUNT(DISTINCT c_customer_id) >= 5
ORDER BY total_store_return_amt DESC
LIMIT 100
